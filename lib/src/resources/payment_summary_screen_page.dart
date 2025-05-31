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
  bool isWaterPaid = true;
  List<Map<String, dynamic>> parkingFees = [];
  int total = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadPaymentData();
  }

  String formatCurrency(int amount) {
    final formatter = NumberFormat("#,###", "vi_VN");
    return "${formatter.format(amount)} đ";
  }

  int _calculateWaterFee(int usage) {
    if (usage <= 10) return usage * 6000;
    if (usage <= 20) return 10 * 6000 + (usage - 10) * 8000;
    return 10 * 6000 + 10 * 8000 + (usage - 20) * 10000;
  }

  Widget _feeRow(String label, int amount, {bool? isPaid, bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 15.sp, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text('${formatCurrency(amount)}${isPaid == true ? " ✅" : ""}',
              style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
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

      // Lấy dữ liệu hợp đồng
      final contractDoc = await FirebaseFirestore.instance
          .collection('contracts')
          .doc(widget.contractId)
          .get();
      contractData = contractDoc.data() ?? {};

      final areaRaw = contractData['area'] ?? 0;
      final area = areaRaw is num ? areaRaw.toDouble() : 0.0;

      // Tính thời điểm đầu và cuối tháng theo targetMonth
      final startOfMonth = DateTime(targetMonth.year, targetMonth.month, 1);
      final endOfMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0);

      // Lấy phí quản lý theo m2 áp dụng đúng thời điểm startOfMonth
      final mgFeeData = await getFeeForDate(
        feeHistoryCollection: FirebaseFirestore.instance
            .collection('services')
            .doc('managementFee')
            .collection('feeHistory'),
        date: startOfMonth,
      );
      final feePerM2Raw = mgFeeData != null ? mgFeeData['feePerM2'] ?? 0 : 0;
      final feePerM2 = feePerM2Raw is num ? feePerM2Raw.toDouble() : 0.0;
      managementFee = (feePerM2 * area).round();

      // Lấy dữ liệu đọc đồng hồ nước tháng được chọn
      final waterSnap = await FirebaseFirestore.instance
          .collection('contracts')
          .doc(widget.contractId)
          .collection('waterReadings')
          .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
          .where('timestamp', isLessThanOrEqualTo: endOfMonth)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      const int maxReading = 9999;

      if (waterSnap.docs.isNotEmpty) {
        final water = waterSnap.docs.first.data();
        final oldReadingRaw = water['oldReading'];
        final newReadingRaw = water['newReading'];

        final oldReading = oldReadingRaw != null ? (oldReadingRaw as num).toInt() : 0;
        final newReading = newReadingRaw != null ? (newReadingRaw as num).toInt() : 0;

        int usage = 0;
        if (newReading >= oldReading) {
          usage = newReading - oldReading;
        } else {
          usage = (maxReading - oldReading) + newReading + 1;
        }

        waterFee = _calculateWaterFee(usage);
        isWaterPaid = water['isPaid'] ?? true;
      } else {
        waterFee = 0;
        isWaterPaid = true;
      }

      // Phí gửi xe
      parkingFees.clear();

      final now = DateTime.now();

      final parkingSnap = await FirebaseFirestore.instance
          .collection('contracts')
          .doc(widget.contractId)
          .collection('parkingRegistrations')
          .where('registeredAt', isLessThanOrEqualTo: endOfMonth)
          .get();

      for (var doc in parkingSnap.docs) {
        final data = doc.data();
        final type = data['vehicleType'];
        final license = data['licensePlate'];
        final registeredAt = (data['registeredAt'] as Timestamp).toDate();
        final canceledAt = data['canceledAt'] != null
            ? (data['canceledAt'] as Timestamp).toDate()
            : null;

        // Loại xe đã huỷ trước tháng đang xét
        if (canceledAt != null && canceledAt.isBefore(startOfMonth)) {
          continue;
        }

        // Xác định khoảng thời gian có hiệu lực trong tháng được chọn
        final effectiveStart = registeredAt.isBefore(startOfMonth) ? startOfMonth : registeredAt;
        final effectiveEnd = (canceledAt == null || canceledAt.isAfter(endOfMonth)) ? endOfMonth : canceledAt;

        // Nếu không có ngày hiệu lực trong tháng thì bỏ qua
        if (effectiveEnd.isBefore(effectiveStart)) continue;

        // Lấy phí theo ngày bắt đầu hiệu lực
        final feeData = await getFeeForDate(
          feeHistoryCollection: FirebaseFirestore.instance
              .collection('services')
              .doc('parking')
              .collection('vehicleTypes')
              .doc(type)
              .collection('feeHistory'),
          date: effectiveStart,
        );

        if (feeData == null) continue;

        final monthlyFeeRaw = feeData['fee'] ?? 0;
        final monthlyFee = monthlyFeeRaw is num ? monthlyFeeRaw.toDouble() : 0.0;

        final totalDaysInMonth = (endOfMonth.difference(startOfMonth).inDays + 1).toDouble();

        // Tính số ngày thực tế đã trôi qua tính từ effectiveStart đến hôm nay (hoặc endOfMonth nếu hôm nay lớn hơn)
        final lastChargeableDay = now.isBefore(endOfMonth) ? now : endOfMonth;

        // Tính activeDays = số ngày từ effectiveStart đến lastChargeableDay, nếu < 0 thì = 0
        int activeDays = lastChargeableDay.difference(effectiveStart).inDays + 1;
        if (activeDays < 0) activeDays = 0;

        // Nếu bạn muốn phí = 0 khi mới ngày đầu tháng (ví dụ hôm nay là 1/6), có thể:
        if (now.day == 1) {
          activeDays = 0;
        }

        final fee = ((monthlyFee / totalDaysInMonth) * activeDays).round();
        parkingFees.add({'licensePlate': license, 'fee': fee});

        print('===== XE =====');
        print('Biển số: $license');
        print('Loại: $type');
        print('registeredAt: $registeredAt');
        print('canceledAt: $canceledAt');
        print('effectiveStart: $effectiveStart');
        print('effectiveEnd: $effectiveEnd');
        print('activeDays: $activeDays');
        print('monthlyFee: $monthlyFee');
        print('Phí tính: $fee');
      }

      total = managementFee + waterFee + parkingFees.fold(0, (sum, p) => sum + (p['fee'] as int));
      setState(() => loading = false);
    } catch (e) {
      print('Lỗi khi tải dữ liệu thanh toán: $e');
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
                _feeRow('Gửi xe (${p['licensePlate']})', p['fee']),
              const Divider(),
              _feeRow('Tổng cộng', total, bold: true),
              SizedBox(height: 20.h),
              if (!isWaterPaid)
                Center(child: ElevatedButton(
                  onPressed: () {
                    // TODO: Xử lý thanh toán hoặc cập nhật trạng thái
                  },
                  child: Text('Thanh toán ngay',style: TextStyle(fontSize: 15.sp)),
                ),)
            ],
          ),
        ),
      ),
    );
  }
}
