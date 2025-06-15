import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class PaymentScreen extends StatefulWidget {
  final String contractId;

  const PaymentScreen({super.key, required this.contractId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Map<String, dynamic> contractData;
  int managementFee = 0;
  int waterFee = 0;
  int debt = 0;
  bool isWaterPaid = true;
  List<Map<String, dynamic>> parkingFees = [];
  int total = 0;
  bool loading = true;
  String paymentStatus = '';
  String? paymentDocId;

  @override
  void initState() {
    super.initState();
    loadPaymentData();
  }

  String formatCurrency(int amount) {
    final formatter = NumberFormat("#,###", "vi_VN");
    return "${formatter.format(amount)} đ";
  }

  Widget _feeRow(String label, int amount, {bool? isPaid, bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            formatCurrency(amount),
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _feeRow1(String label, int amount, {bool? isPaid, bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.red,
              fontSize: 15.sp,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            formatCurrency(amount),
            style: TextStyle(
              color: Colors.red,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> getFeeForDate({
    required CollectionReference feeHistoryCollection,
    required DateTime date,
  }) async {
    final snap = await feeHistoryCollection
        .where('effectiveFrom', isLessThanOrEqualTo: Timestamp.fromDate(date))
        .orderBy('effectiveFrom', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      final data = snap.docs.first.data();
      if (data is Map<String, dynamic>) {
        return data;
      } else {
        // Nếu không phải Map<String, dynamic> thì có thể xử lý ở đây hoặc trả null
        return null;
      }
    }
    return null;
  }

  Future<void> loadPaymentData({DateTime? forMonth}) async {
    try {
      setState(() => loading = true);

      final DateTime targetMonth = forMonth ?? DateTime.now();
      final formattedMonth = DateFormat('MM-yyyy').format(targetMonth); // ví dụ "06-2025"

      // Lấy dữ liệu hợp đồng
      final contractDoc = await FirebaseFirestore.instance
          .collection('contracts')
          .doc(widget.contractId)
          .get();

      contractData = contractDoc.data() ?? {};

      // Lấy dữ liệu thanh toán trong subcollection 'payments' cho tháng đang xét
      final paymentQuery = await FirebaseFirestore.instance
          .collection('contracts')
          .doc(widget.contractId)
          .collection('payments')
          .where('month', isEqualTo: formattedMonth)
          .limit(1)
          .get();

      if (paymentQuery.docs.isEmpty) {
        managementFee = 0;
        waterFee = 0;
        total = 0;
        parkingFees = [];
        isWaterPaid = true;
        paymentStatus = 'Không có dữ liệu';
      } else {
        final doc = paymentQuery.docs.first;
        final payment = doc.data();
        debt = (payment['debt'] ?? 0) as int;

        paymentDocId = doc.id;

        managementFee = (payment['managementFee'] ?? 0) as int;
        waterFee = (payment['waterFee'] ?? 0) as int;
        total = (payment['total'] ?? 0) as int;

        final parkingFee = (payment['parkingFee'] ?? 0) as int;
        parkingFees = parkingFee > 0
            ? [{'licensePlate': 'Xe', 'fee': parkingFee}]
            : [];

        isWaterPaid = (payment['waitingForWater'] == false);
        paymentStatus = (payment['status'] ?? '');
      }

      setState(() => loading = false);
    } catch (e) {
      print('❌ Lỗi khi tải dữ liệu thanh toán: $e');
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final now = DateTime.now();
    final monthLabel = "${now.month}/${now.year}";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chi tiết thanh toán',
          style: TextStyle(
            color: Colors.white,
            fontFamily: "Oswald",
            fontWeight: FontWeight.bold,
            fontSize: 25.sp,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Căn hộ: ${contractData['apartmentName']} (${contractData['building']})',
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 20.h),
              Text('Diện tích: ${contractData['area']} m²',style: TextStyle(fontSize: 15.sp)),
              SizedBox(height: 20.h),
              Text('Đại diện: ${contractData['representative']['fullName']}',style: TextStyle(fontSize: 15.sp)),
              SizedBox(height: 20.h),
              Text('Kỳ thanh toán: $monthLabel',style: TextStyle(fontSize: 15.sp)),
              SizedBox(height: 20.h),
              const Divider(),
              Text('Chi tiết phí:', style: TextStyle(fontSize: 15.sp,fontWeight: FontWeight.bold)),
              _feeRow('Phí quản lý', managementFee),
              _feeRow('Phí nước', waterFee, isPaid: isWaterPaid),
              for (var p in parkingFees)
                _feeRow('Gửi xe', p['fee']),
              const Divider(),
              _feeRow('Tổng cộng', total, bold: true),
              if (debt > 0)
                _feeRow1('Công nợ', debt),
              SizedBox(height: 20.h),
              if (paymentStatus != 'Đã thanh toán' && paymentStatus != 'Đã thanh toán (chưa kiểm tra)' && paymentDocId != null)
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection("contracts")
                          .doc(widget.contractId)
                          .collection("payments")
                          .doc(paymentDocId)
                          .update({
                        'status': 'Đã thanh toán (chưa kiểm tra)',
                      });
                      // Refresh lại sau khi cập nhật
                      await loadPaymentData();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Đã cập nhật trạng thái thanh toán, vui lòng chờ kiểm tra"),backgroundColor: Colors.green,),
                      );
                    },
                    child: Text('Thanh toán ngay', style: TextStyle(fontSize: 15.sp)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
