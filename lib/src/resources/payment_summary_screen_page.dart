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
  int _selectedTab = 0;

  int managementFee = 0;
  int waterFee = 0;
  int debt = 0;
  int total = 0;
  bool isWaterPaid = true;
  List<Map<String, dynamic>> parkingFees = [];
  bool loading = true;
  String paymentStatus = '';
  String? paymentDocId;
  late Map<String, dynamic> contractData;

  @override
  void initState() {
    super.initState();
    loadPaymentData();
  }

  String formatCurrency(int amount) {
    final formatter = NumberFormat("#,###", "vi_VN");
    return "${formatter.format(amount)} đ";
  }

  Future<void> loadPaymentData({DateTime? forMonth}) async {
    try {
      setState(() => loading = true);

      final DateTime targetMonth = forMonth ?? DateTime.now();
      final formattedMonth = DateFormat('MM-yyyy').format(targetMonth);

      final contractDoc = await FirebaseFirestore.instance
          .collection('contracts')
          .doc(widget.contractId)
          .get();

      contractData = contractDoc.data() ?? {};

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

  Widget _buildTabButton(String label, int index, bool isActive) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedTab = index;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
        foregroundColor: isActive ? Colors.white : Colors.black,
      ),
      child: Text(label, style: TextStyle(fontSize: 15.sp)),
    );
  }

  Widget _feeRow(String label, int amount, {bool bold = false, bool red = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14.sp, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: red ? Colors.red : null)),
          Text(formatCurrency(amount), style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: red ? Colors.red : null)),
        ],
      ),
    );
  }

  Widget _buildCurrentPaymentTab() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final now = DateTime.now();
    final monthLabel = "${now.month}/${now.year}";

    return SingleChildScrollView(
      padding: EdgeInsets.only(right: 16.w, left: 16.w, top: 5.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 150.h,
              width: 150.h,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black, // Màu viền
                  width: 0.2, // Độ dày viền
                ),
                borderRadius: BorderRadius.circular(12), // Bo góc nếu muốn
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/thanhtoan.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text('Căn hộ: ${contractData['apartmentName']} (${contractData['building']})',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 12.h),
          Text('Diện tích: ${contractData['area']} m²', style: TextStyle(fontSize: 14.sp)),
          SizedBox(height: 12.h),
          Text('Đại diện: ${contractData['representative']['fullName']}', style: TextStyle(fontSize: 14.sp)),
          SizedBox(height: 12.h),
          Text('Kỳ thanh toán: $monthLabel', style: TextStyle(fontSize: 14.sp)),
          _buildStatusText(),
          const Divider(height: 30),
          Text('Chi tiết phí:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp)),
          _feeRow('Phí quản lý', managementFee),
          _feeRow('Phí nước', waterFee),
          for (var p in parkingFees) _feeRow('Gửi xe', p['fee']),
          const Divider(),
          _feeRow('Tổng cộng', total, bold: true),

          // Công nợ hoặc còn thiếu
          if (debt > 0 && paymentStatus == 'Chưa thanh toán')
            _feeRow('Công nợ', debt, red: true),
          if (debt > 0 && paymentStatus == 'Chưa thanh toán đủ')
            _feeRow('Còn thiếu', debt, red: true),

          SizedBox(height: 20.h),

          // Nút Xác nhận thanh toán luôn hiển thị, nhưng có thể bị vô hiệu hóa
          Center(
            child: ElevatedButton(
              onPressed: (paymentStatus == 'Đã thanh toán' ||
                  paymentStatus == 'Đã thanh toán (chờ kiểm tra)' ||
                  paymentDocId == null)
                  ? null
                  : () async {
                await FirebaseFirestore.instance
                    .collection("contracts")
                    .doc(widget.contractId)
                    .collection("payments")
                    .doc(paymentDocId!)
                    .update({'status': 'Đã thanh toán (chờ kiểm tra)'});

                await loadPaymentData();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Đã cập nhật trạng thái thanh toán, vui lòng chờ kiểm tra"), backgroundColor: Colors.green),
                );
              },
              child: Text('Xác nhận thanh toán', style: TextStyle(fontSize: 15.sp,color:Colors.black)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection("contracts")
          .doc(widget.contractId)
          .collection("payments")
          .orderBy("month", descending: true)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(child: Text("Chưa có lịch sử thanh toán"));
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => SizedBox(height: 10.h),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final month = data['month'] ?? '';
            final status = data['status'] ?? 'Chưa rõ';
            final total = data['total'] ?? 0;

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  _showPaymentDetailDialog(context, data, doc.id);
                },
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thông tin bên trái
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Kỳ: $month", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                            SizedBox(height: 8.h),
                            Text("Trạng thái: $status", style: TextStyle(fontSize: 14.sp)),
                            SizedBox(height: 8.h),
                            Text("Tổng tiền: ${formatCurrency(total)}", style: TextStyle(fontSize: 14.sp)),
                          ],
                        ),
                      ),

                      // Icon trạng thái
                      Icon(
                        _getStatusIcon(status),
                        color: _getStatusColor(status),
                        size: 28.w,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPaymentDetailDialog(BuildContext context, Map<String, dynamic> paymentData, String docId) {
    final month = paymentData['month'] ?? '';
    final managementFee = paymentData['managementFee'] ?? 0;
    final waterFee = paymentData['waterFee'] ?? 0;
    final parkingFee = paymentData['parkingFee'] ?? 0;
    final total = paymentData['total'] ?? 0;
    final debt = paymentData['debt'] ?? 0;
    final status = paymentData['status'] ?? 'Chưa rõ';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Chi tiết kỳ $month", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _feeRow("Phí quản lý", managementFee),
              _feeRow("Phí nước", waterFee),
              if (parkingFee > 0) _feeRow("Gửi xe", parkingFee),
              Divider(),
              _feeRow("Tổng cộng", total, bold: true),
              if (debt > 0 && status == 'Chưa thanh toán')
                _feeRow('Công nợ', debt, red: true),
              if (debt > 0 && status == 'Chưa thanh toán đủ')
                _feeRow('Còn thiếu', debt, red: true),
              SizedBox(height: 12.h),
              Text("Trạng thái: $status", style: TextStyle(fontSize: 14.sp)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text("Đóng", style: TextStyle(fontSize: 14.sp)),
          )
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Đã thanh toán':
        return Icons.check_circle;
      case 'Đã thanh toán (chờ kiểm tra)':
        return Icons.hourglass_top;
      case 'Chưa thanh toán đủ':
        return Icons.warning;
      case 'Chưa thanh toán':
      default:
        return Icons.error;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Đã thanh toán':
        return Colors.green;
      case 'Đã thanh toán (chờ kiểm tra)':
        return Colors.blue;
      case 'Chưa thanh toán đủ':
        return Colors.deepOrange;
      case 'Chưa thanh toán':
      default:
        return Colors.red;
    }
  }

  Widget _buildStatusText() {
    String text;
    Color color;

    switch (paymentStatus) {
      case 'Đã thanh toán':
        text = "Trạng thái: Đã thanh toán đủ";
        color = Colors.green;
        break;
      case 'Đã thanh toán (chờ kiểm tra)':
        text = "Trạng thái: Đã thanh toán - chờ kiểm tra";
        color = Colors.blue;
        break;
      case 'Chưa thanh toán đủ':
        text = "Trạng thái: Chưa thanh toán đủ";
        color = Colors.deepOrange;
        break;
      case 'Chưa thanh toán':
      default:
        text = "Trạng thái: Chưa thanh toán";
        color = Colors.red;
        break;
    }

    return Padding(
      padding: EdgeInsets.only(top: 12.h),
      child: Text(
        text,
        style: TextStyle(fontSize: 14.sp, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Thanh toán',
          style: TextStyle(
            color: Colors.white,
            fontFamily: "Oswald",
            fontWeight: FontWeight.bold,
            fontSize: 25.sp,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(right: 16.w, left: 16.w, top: 20.h, bottom: 5.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTabButton("Phí tháng hiện tại", 0, _selectedTab == 0),
                  SizedBox(width: 12.w),
                  _buildTabButton("Lịch sử các tháng", 1, _selectedTab == 1),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: _selectedTab == 0 ? _buildCurrentPaymentTab() : _buildHistoryTab(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
