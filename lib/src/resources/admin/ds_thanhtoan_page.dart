import 'dart:async'; // Thêm import Timer
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:do_an/constants.dart';
import 'package:do_an/custom_paginated_table.dart';
import 'package:do_an/src/models/apartment.dart';
import 'package:do_an/src/models/contract_data.dart';
import 'package:do_an/src/resources/provider/contract_notifier_provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  List<Apartment> allApartments = [];
  List<Apartment> filteredApartments = [];

  String? selectedBuilding;
  int? selectedFloor;
  String searchQuery = "";
  String? selectedContractStatus;

  Timer? _debounce;

  String formatCurrency(dynamic amount) {
    if (amount == null) return "0 đ";
    final formatter = NumberFormat("#,###", "vi_VN");
    return "${formatter.format(amount)} đ";
  }

  late ContractNotifier contractNotifier;

  double minArea = 50;
  double maxArea = 120;

  RangeValues selectedAreaRange = const RangeValues(50, 120);

  double minFunction(double a, double b) => a < b ? a : b;

  double maxFunction(double a, double b) => a > b ? a : b;

  int currentPage = 1; // Trang hiện tại
  int itemsPerPage = 10; // Số lượng căn hộ mỗi trang
  List<Apartment> paginatedApartments = []; // Căn hộ hiển thị trên mỗi trang
  int totalPages = 0; // Tổng số trang
  List<int> pageNumbers = []; // Danh sách số trang cần hiển thị (1, 2, 3)

  bool _isDialogShowing = false;

  Map<String, String> representativeNames = {};

  Future<void> fetchRepresentativeNames(List<Apartment> apartments) async {
    for (final apartment in apartments) {
      final doc = await FirebaseFirestore.instance
          .collection('apartments')
          .doc(apartment.id)
          .get();

      final contractId = doc.data()?['currentContractId'];
      if (contractId != null) {
        final contractDoc = await FirebaseFirestore.instance
            .collection('contracts')
            .doc(contractId)
            .get();

        final rep = contractDoc.data()?['representative'];
        final fullName = rep?['fullName'];
        if (fullName != null) {
          representativeNames[apartment.id] = fullName;
        }
      }
    }
  }

  void updatePaginatedApartments() {
    setState(() {
      int startIndex = (currentPage - 1) * itemsPerPage;
      int endIndex = startIndex + itemsPerPage;
      if (endIndex > filteredApartments.length) {
        endIndex = filteredApartments.length;
      }

      paginatedApartments = filteredApartments.sublist(startIndex, endIndex);
      totalPages = (filteredApartments.length / itemsPerPage).ceil();
      updatePageNumbers(); // Hàm này cần đảm bảo giao diện được làm mới
    });
  }

// Cập nhật danh sách các số trang (1, 2, 3, ...)
  void updatePageNumbers() {
    int startPage = currentPage - 1;
    if (startPage < 0) startPage = 0;

    pageNumbers = List.generate(3, (index) {
      int page = startPage + index;
      if (page < totalPages) {
        return page + 1; // Trả về trang hợp lệ
      }
      return -1; // Trả về giá trị không hợp lệ
    }).where((page) => page != -1).toList(); // Lọc bỏ giá trị -1
  }

  Map<String, bool> hasActiveContract = {}; // Khai báo ở cấp độ State

  Future<void> loadApartmentsFromFirestore() async {
    try {
      final snapshot =
      await FirebaseFirestore.instance.collection('apartments').get();
      final contractSnapshot = await FirebaseFirestore.instance
          .collection('contracts')
          .where('isActive', isEqualTo: true)
          .get();

      List<Apartment> apartments = [];

      for (var doc in snapshot.docs) {
        try {
          apartments.add(Apartment.fromFirestore(doc));
        } catch (e) {
          print('❌ Error parsing document ${doc.id}: $e');
        }
      }

      // Tạo map các apartmentId đang có hợp đồng active
      Map<String, bool> activeContractMap = {};
      for (var doc in contractSnapshot.docs) {
        final data = doc.data();
        final apartmentId = data['apartmentDocId'];
        if (apartmentId != null) {
          activeContractMap[apartmentId] = true;
        }
      }

      apartments.sort((a, b) {
        int buildingCompare = a.building.compareTo(b.building);
        if (buildingCompare != 0) return buildingCompare;
        int floorCompare = a.floor.compareTo(b.floor);
        if (floorCompare != 0) return floorCompare;
        return a.apartmentName.compareTo(b.apartmentName);
      });

      if (mounted) {
        setState(() {
          allApartments = apartments;
          filteredApartments = apartments;
          hasActiveContract = activeContractMap;
          updatePaginatedApartments();
        });
      }
      await fetchRepresentativeNames(apartments);
    } catch (e) {
      print('Error loading apartments: $e');
    }
  }

  List<String> getAvailableBuildings() {
    return allApartments.map((a) => a.building).toSet().toList()..sort();
  }

  // Hàm debounce để tối ưu hiệu suất tìm kiếm
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        searchQuery = query;
        applyFilters(); // Gọi lại hàm lọc khi thay đổi giá trị tìm kiếm
      });
    });
  }

  void applyFilters() {
    List<Apartment> result = allApartments;

    if (selectedBuilding != null) {
      result = result.where((a) => a.building == selectedBuilding).toList();
    }

    if (selectedFloor != null) {
      result = result.where((a) => a.floor == selectedFloor).toList();
    }

    result = result
        .where((a) =>
    a.area >= selectedAreaRange.start &&
        a.area <= selectedAreaRange.end)
        .toList();

    if (searchQuery.isNotEmpty) {
      result = result
          .where((a) =>
          a.apartmentName.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    // ✅ Lọc theo trạng thái hợp đồng (hỗ trợ "all", "contract", "empty")
    if (selectedContractStatus == "contract") {
      result = result.where((a) => a.status == 'Đang cho thuê').toList();
    } else if (selectedContractStatus == "empty") {
      result = result.where((a) => a.status == 'Trống').toList();
    }
    // Nếu là "all" hoặc null thì không lọc thêm

    filteredApartments = result;
    currentPage = 1;
    updatePaginatedApartments();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> showApartmentContractInfoDialog(
      BuildContext context,
      Apartment apartment,
      Contract contract,
      VoidCallback onRefresh,
      ) async {
    try {
      final contractQuery = await FirebaseFirestore.instance
          .collection("contracts")
          .where("apartmentDocId", isEqualTo: apartment.id)
          .where("isActive", isEqualTo: true)
          .limit(1)
          .get();

      if (contractQuery.docs.isEmpty) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Thông tin hợp đồng",
                style: TextStyle(
                    fontSize: 4.sp,
                    fontFamily: "Oswald",
                    fontWeight: FontWeight.bold)),
            content: Text("Căn hộ này không có hợp đồng còn hiệu lực.",
                style: TextStyle(fontSize: 3.5.sp)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Đóng", style: TextStyle(fontSize: 3.5.sp)),
              ),
            ],
          ),
        );
        return;
      }

      final contractDoc = contractQuery.docs.first;
      final contract = Contract.fromMap(contractDoc.data(), contractDoc.id, []);

      final paymentsSnap = await FirebaseFirestore.instance
          .collection("contracts")
          .doc(contract.contractId)
          .collection("payments")
          .orderBy("month", descending: true)
          .limit(1)
          .get();

      Map<String, dynamic>? latestPayment;
      if (paymentsSnap.docs.isNotEmpty) {
        latestPayment = paymentsSnap.docs.first.data();
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Center(
            child: Text(
              "Hóa đơn hiện tại",
              style: TextStyle(
                  fontSize: 7.sp,
                  fontFamily: "Oswald",
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent
              ),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (latestPayment != null) ...[
                  Divider(),
                  Text(
                    "${contract.building} / Phòng ${contract.apartmentName}",
                    style: TextStyle(fontSize: 4.sp),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    "Người đại diện: ${contract.representative?['fullName'] ?? 'Không có'}",
                    style: TextStyle(fontSize: 4.sp),
                  ),
                  SizedBox(height: 10.h),
                  Text("Tiền quản lý: ${formatCurrency(latestPayment['managementFee'])}",
                      style: TextStyle(fontSize: 4.sp)),
                  SizedBox(height: 10.h),
                  Text("Tiền nước: ${formatCurrency(latestPayment['waterFee'])}",
                      style: TextStyle(fontSize: 4.sp)),
                  SizedBox(height: 10.h),
                  Text("Tiền gửi xe: ${formatCurrency(latestPayment['parkingFee'])}",
                      style: TextStyle(fontSize: 4.sp)),

                  SizedBox(height: 10.h),
                  Text("Tổng: ${formatCurrency(latestPayment['total'])}",
                      style: TextStyle(fontSize: 4.sp)),
                  SizedBox(height: 10.h),
                  Text("Trạng thái: ${latestPayment['status']}",
                      style: TextStyle(fontSize: 4.sp)),

                  if ((latestPayment['status'] == 'Chưa thanh toán' && (latestPayment['debt'] ?? 0) > 0))
                    Padding(
                      padding: EdgeInsets.only(top: 10.h),
                      child: Text(
                        "Công nợ: ${formatCurrency(latestPayment['debt'])}",
                        style: TextStyle(fontSize: 4.sp, color: Colors.red),
                      ),
                    )
                  else if ((latestPayment['status'] == 'Chưa thanh toán đủ' && (latestPayment['debt'] ?? 0) > 0))
                    Padding(
                      padding: EdgeInsets.only(top: 10.h),
                      child: Text(
                        "Còn thiếu: ${formatCurrency(latestPayment['debt'])}",
                        style: TextStyle(fontSize: 4.sp, color: Colors.red),
                      ),
                    )
                ] else ...[
                  Padding(
                    padding: EdgeInsets.only(top: 20.h),
                    child: Center(
                      child: Text(
                        "Chưa có dữ liệu thanh toán",
                        style: TextStyle(fontSize: 4.sp, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          actions: [
            if (latestPayment != null) ...[
              TextButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Center(child: Text("Xác nhận", style: TextStyle(fontSize: 7.sp,fontWeight: FontWeight.bold,color: Colors.blueAccent,fontFamily: "Oswald"))),
                      content: Text(
                        "Bạn có chắc chắn muốn xác nhận đã thanh toán đầy đủ?",
                        style: TextStyle(fontSize: 4.sp),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text("Hủy", style: TextStyle(fontSize: 3.5.sp)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text("Xác nhận", style: TextStyle(fontSize: 3.5.sp)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await FirebaseFirestore.instance
                        .collection("contracts")
                        .doc(contract.contractId)
                        .collection("payments")
                        .doc(paymentsSnap.docs.first.id)
                        .update({
                      'status': 'Đã thanh toán',
                      'debt': 0,
                    });

                    await FirebaseFirestore.instance
                        .collection("contracts")
                        .doc(contract.contractId)
                        .collection("waterReadings")
                        .doc(latestPayment!['month']) // ví dụ: "05-2025"
                        .update({'isPaid': true});

                    Navigator.pop(context); // Đóng dialog chính
                    await showApartmentContractInfoDialog(context, apartment, contract, onRefresh);
                  }
                },
                child: Text("Xác nhận đã thanh toán", style: TextStyle(fontSize: 3.5.sp)),
              ),
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) {
                      final debtController = TextEditingController();
                      return AlertDialog(
                        title: Center(child: Text("Nhập số tiền còn thiếu", style: TextStyle(fontSize: 5.sp,fontWeight: FontWeight.bold,color: Colors.blueAccent,fontFamily: "Oswald")),),
                        content: TextField(
                          controller: debtController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(hintText: "Nhập số tiền nợ"),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("Hủy", style: TextStyle(fontSize: 3.5.sp)),
                          ),
                          TextButton(
                            onPressed: () async {
                              final text = debtController.text.trim();
                              final debt = int.tryParse(text);

                              final total = latestPayment!['total'];
                              if (text.isEmpty || debt == null || debt <= 0 || debt >= total) {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Center(child: Text("Lỗi", style: TextStyle(fontSize: 5.sp)),),
                                    content: Text(
                                      "Vui lòng nhập số tiền nợ hợp lệ (lớn hơn 0 và nhỏ hơn tổng tiền phải thanh toán: $total đ).",
                                      style: TextStyle(fontSize: 4.sp),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text("OK", style: TextStyle(fontSize: 3.5.sp)),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }

                              await FirebaseFirestore.instance
                                  .collection("contracts")
                                  .doc(contract.contractId)
                                  .collection("payments")
                                  .doc(paymentsSnap.docs.first.id)
                                  .update({
                                'status': 'Chưa thanh toán đủ',
                                'debt': debt,
                              });

                              await FirebaseFirestore.instance
                                  .collection("contracts")
                                  .doc(contract.contractId)
                                  .collection("waterReadings")
                                  .doc(latestPayment!['month']) // ví dụ: "05-2025"
                                  .update({'isPaid': false});

                              Navigator.pop(context); // Đóng dialog nhập nợ
                              Navigator.pop(context); // Đóng dialog chính
                              await showApartmentContractInfoDialog(context, apartment, contract, onRefresh);
                            },
                            child: Text("Xác nhận", style: TextStyle(fontSize: 3.5.sp)),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Text("Xác nhận thiếu", style: TextStyle(fontSize: 3.5.sp)),
              ),
            ],
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Đóng", style: TextStyle(fontSize: 3.5.sp)),
            ),
          ],
        ),
      );
    } catch (e) {
      print("❌ Lỗi khi hiển thị thông tin: $e");
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Lỗi", style: TextStyle(fontSize: 6.sp)),
          content: Text("Không thể lấy thông tin hợp đồng.",
              style: TextStyle(fontSize: 4.sp)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Đóng", style: TextStyle(fontSize: 4.sp)))
          ],
        ),
      );
    }
  }

  Future<void> triggerBillCalculation(String contractId) async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('generatePaymentNow')
          .call({"contractId": contractId});
      print(result.data['message']);
    } catch (e) {
      print('❌ Lỗi khi gọi hàm tạo bill: $e');
    }
  }

  Future<void> showPaymentHistoryDialog(
      BuildContext context,
      String contractId,
      DateTime startDate,
      DateTime endDate,
      ) async {
    try {
      final paymentsSnap = await FirebaseFirestore.instance
          .collection("contracts")
          .doc(contractId)
          .collection("payments")
          .orderBy("month", descending: true)
          .get();

      final allPayments = paymentsSnap.docs
          .map((doc) => doc.data())
          .where((data) {
        final monthStr = data['month'];
        try {
          final parts = monthStr.split("/");
          final month = int.parse(parts[0]);
          final year = int.parse(parts[1]);
          final date = DateTime(year, month);
          return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
              date.isBefore(endDate.add(const Duration(days: 1)));
        } catch (e) {
          return false;
        }
      })
          .toList();

      if (allPayments.isEmpty) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Center(child:Text("Lịch sử thanh toán",style: TextStyle(
                fontSize: 7.sp,
                fontFamily: "Oswald",
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent
            ),),),
            content: Text("Không có dữ liệu thanh toán trong khoảng thời gian này.",
                style: TextStyle(fontSize: 4.sp)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Đóng", style: TextStyle(fontSize: 3.5.sp)),
              ),
            ],
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Lịch sử thanh toán", style: TextStyle(
              fontSize: 7.sp,
              fontFamily: "Oswald",
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent
          ),),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                children: allPayments.map((payment) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(),
                      Text("Tháng ${payment['month']}", style: TextStyle(fontSize: 4.sp, fontWeight: FontWeight.bold)),
                      Text("  ▸ Tiền quản lý: ${payment['managementFee']} đ", style: TextStyle(fontSize: 3.5.sp)),
                      Text("  ▸ Tiền nước: ${payment['waterFee']} đ", style: TextStyle(fontSize: 3.5.sp)),
                      Text("  ▸ Tiền gửi xe: ${payment['parkingFee']} đ", style: TextStyle(fontSize: 3.5.sp)),
                      Text("  ▸ Tổng: ${payment['total']} đ", style: TextStyle(fontSize: 3.5.sp)),
                      Text("  ▸ Trạng thái: ${payment['status']}", style: TextStyle(fontSize: 3.5.sp)),
                      if (payment['status'] == 'Chưa thanh toán đủ' && payment['debt'] != null)
                        Text("  ▸ Còn thiếu: ${payment['debt']} đ", style: TextStyle(fontSize: 3.5.sp, color: Colors.red)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Đóng", style: TextStyle(fontSize: 3.5.sp)),
            ),
          ],
        ),
      );
    } catch (e) {
      print("❌ Lỗi khi lấy lịch sử thanh toán: $e");
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Lỗi", style: TextStyle(fontSize: 5.sp)),
          content: Text("Không thể lấy lịch sử thanh toán.", style: TextStyle(fontSize: 4.sp)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Đóng", style: TextStyle(fontSize: 4.sp)),
            ),
          ],
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    loadApartmentsFromFirestore();
    fetchAreaRangeFromFirestore();
    filteredApartments = allApartments;
    currentPage = 1;
    updatePaginatedApartments();
  }

  Future<void> fetchAreaRangeFromFirestore() async {
    final snapshot =
    await FirebaseFirestore.instance.collection('apartments').get();
    final areas =
    snapshot.docs.map((doc) => (doc['area'] as num).toDouble()).toList();

    if (areas.isNotEmpty) {
      final min = areas.reduce(minFunction);
      final max = areas.reduce(maxFunction);

      if (mounted) {
        // Kiểm tra widget có còn tồn tại
        setState(() {
          minArea = min;
          maxArea = max;
          selectedAreaRange = RangeValues(minArea, maxArea);
        });
      }
    }
  }

  List<int> getFloorsByBuilding(List<Apartment> apartments, String selectedBuilding) {
    final filtered =
    apartments.where((apt) => apt.building == selectedBuilding);
    final floors = filtered.map((apt) => apt.floor).toSet().toList();
    floors.sort();
    return floors;
  }

  List<int> getFloorsForSelectedBuilding() {
    if (selectedBuilding == null) {
      return [];
    }
    return getFloorsByBuilding(allApartments, selectedBuilding!);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Gán chỉ 1 lần
    contractNotifier = Provider.of<ContractNotifier>(context, listen: true);

    // Dùng post-frame callback để tránh lỗi gọi notifyListeners trong build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (contractNotifier.contractCreated) {
        loadApartmentsFromFirestore();
        contractNotifier.reset();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                        left: 10.w, right: 10.w, top: 40.h, bottom: 10.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Phần tiêu đề
                            Flexible(
                              flex: 1,
                              child: Text(
                                "Quản lý thanh toán",
                                style: TextStyle(
                                  fontFamily: "Oswald",
                                  fontWeight: FontWeight.w700,
                                  fontSize: 7.sp,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 5.w,
                            ),
                            // Ô tìm kiếm
                            Flexible(
                              flex: 1,
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: "Tìm kiếm căn hộ",
                                  labelStyle: TextStyle(fontSize: 4.sp),
                                  hintText: "Nhập tên căn hộ",
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30.r),
                                  ),
                                ),
                                onChanged: _onSearchChanged,
                              ),
                            ),
                            Flexible(
                              flex: 1,
                              child: SizedBox(
                                height: 55.h,
                                width: 40.w,
                                child: ElevatedButton(
                                  onPressed: () => triggerBillCalculation("Yz4ySEUebkMfCIFE6NYm"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    secondaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(30.r),
                                    ),
                                    elevation: 4,
                                    shadowColor: Colors.black45,
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(
                                    'Tính hóa đơn',
                                    style: TextStyle(
                                        fontSize: 4.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 5.w,
                            )
                          ],
                        ),
                        SizedBox(height: 20.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: buildFilterDropdown<String>(
                                label: "Trạng thái",
                                items: ["all", "contract", "empty"],
                                selectedValue: selectedContractStatus,
                                onChanged: (value) {
                                  setState(() {
                                    selectedContractStatus = value;
                                    applyFilters();
                                  });
                                },
                                itemLabelBuilder: (item) {
                                  if (item == "all") return "Tất cả";
                                  if (item == "contract") return "Đang cho thuê";
                                  if (item == "empty") return "Trống";
                                  return item;
                                },
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: buildFilterDropdown<String>(
                                label: "Chọn tòa",
                                items: getAvailableBuildings(),
                                selectedValue: selectedBuilding,
                                onChanged: (value) {
                                  setState(() {
                                    selectedBuilding = value;
                                    selectedFloor = null;
                                  });
                                  applyFilters();
                                },
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: buildFilterDropdown<int>(
                                label: "Chọn tầng",
                                items: getFloorsForSelectedBuilding(),
                                selectedValue: selectedFloor,
                                itemLabelBuilder: (floor) => "Tầng $floor",
                                onChanged: (value) {
                                  setState(() {
                                    selectedFloor = value;
                                  });
                                  applyFilters();
                                },
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: buildAreaFilter(),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 20.h,
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height - 150.h,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Column(
                                children: [
                                  if (allApartments.isEmpty)
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          'Không có căn hộ nào',
                                          style: TextStyle(
                                            fontSize: 4.sp,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minWidth: constraints.maxWidth,
                                            // Đặt chiều rộng tối thiểu bằng chiều rộng cha
                                            maxWidth: constraints
                                                .maxWidth, // Đặt chiều rộng tối đa bằng chiều rộng cha
                                          ),
                                          child: CustomPaginatedTable(
                                            columns: [
                                              DataColumn(
                                                  label: Text("Tòa",
                                                      style: TextStyle(
                                                          fontSize: 4.sp))),
                                              DataColumn(
                                                  label: Text("Tên căn hộ",
                                                      style: TextStyle(
                                                          fontSize: 4.sp))),
                                              DataColumn(
                                                  label: Text("Tầng",
                                                      style: TextStyle(
                                                          fontSize: 4.sp))),
                                              DataColumn(
                                                  label: Text("Diện tích",
                                                      style: TextStyle(
                                                          fontSize: 4.sp))),
                                              DataColumn(
                                                  label: Text("Trạng thái dịch vụ",
                                                      style: TextStyle(
                                                          fontSize: 4.sp))),
                                              DataColumn(
                                                  label: Text("Người đại diện",
                                                      style: TextStyle(
                                                          fontSize: 4.sp))),
                                              DataColumn(
                                                  label: Text("Hành động",
                                                      style: TextStyle(
                                                          fontSize: 4.sp))),
                                            ],
                                            rows:
                                            filteredApartments.map((apartment) {
                                              final isRented = apartment.status ==
                                                  'Đang cho thuê';
                                              final hasContract =
                                                  hasActiveContract[apartment.id] ??
                                                      false;
                                              return DataRow(cells: [
                                                DataCell(Text(apartment.building,
                                                    style:
                                                    TextStyle(fontSize: 4.sp))),
                                                DataCell(Text(
                                                    apartment.apartmentName,
                                                    style:
                                                    TextStyle(fontSize: 4.sp))),
                                                DataCell(Text("${apartment.floor}",
                                                    style:
                                                    TextStyle(fontSize: 4.sp))),
                                                DataCell(Text(
                                                    "${apartment.area} m²",
                                                    style:
                                                    TextStyle(fontSize: 4.sp))),
                                                DataCell(Text("${apartment.status}",
                                                    style:
                                                    TextStyle(fontSize: 4.sp))),
                                                DataCell(Text(representativeNames[apartment.id] ?? '-', style: TextStyle(fontSize: 4.sp))),
                                                DataCell(
                                                  Row(
                                                    children: [
                                                      IconButton(
                                                        tooltip: 'Thông tin hợp đồng',
                                                        icon: Icon(
                                                          Icons.info_outline,
                                                          color: (isRented && hasContract) ? Colors.white : Colors.grey,
                                                        ),
                                                        onPressed: (isRented && hasContract)
                                                            ? () async {
                                                          if (_isDialogShowing) return;
                                                          _isDialogShowing = true;
                                                          try {
                                                            final query = await FirebaseFirestore.instance
                                                                .collection('contracts')
                                                                .where('apartmentDocId', isEqualTo: apartment.id)
                                                                .where('isActive', isEqualTo: true)
                                                                .limit(1)
                                                                .get();

                                                            if (query.docs.isEmpty) return;

                                                            final contract = Contract.fromMap(
                                                              query.docs.first.data(),
                                                              query.docs.first.id,
                                                              [],
                                                            );

                                                            await showApartmentContractInfoDialog(
                                                              context,
                                                              apartment,
                                                              contract,
                                                              loadApartmentsFromFirestore,
                                                            );
                                                          } catch (e) {
                                                            print('❌ Lỗi show info: $e');
                                                          } finally {
                                                            _isDialogShowing = false;
                                                          }
                                                        }
                                                            : null,
                                                      ),
                                                      IconButton(
                                                        tooltip: 'Lịch sử thanh toán',
                                                        icon: Icon(
                                                          Icons.history,
                                                          color: (isRented && hasContract) ? Colors.white : Colors.grey,
                                                        ),
                                                        onPressed: (isRented && hasContract)
                                                            ? () async {
                                                          if (_isDialogShowing) return;
                                                          _isDialogShowing = true;
                                                          try {
                                                            final query = await FirebaseFirestore.instance
                                                                .collection('contracts')
                                                                .where('apartmentDocId', isEqualTo: apartment.id)
                                                                .where('isActive', isEqualTo: true)
                                                                .limit(1)
                                                                .get();

                                                            if (query.docs.isEmpty) return;

                                                            final contract = Contract.fromMap(
                                                              query.docs.first.data(),
                                                              query.docs.first.id,
                                                              [],
                                                            );

                                                            await showPaymentHistoryDialog(
                                                              context,
                                                              contract.contractId!,
                                                              contract.startDate,
                                                              contract.endDate!,
                                                            );
                                                          } catch (e) {
                                                            print('❌ Lỗi show history: $e');
                                                          } finally {
                                                            _isDialogShowing = false;
                                                          }
                                                        }
                                                            : null,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ]);
                                            }).toList(),
                                            rowsPerPage: itemsPerPage,
                                            availableRowsPerPage: [5, 10, 20, 50],
                                            // Các tùy chọn số dòng mỗi trang
                                            onRowsPerPageChanged: (value) {
                                              setState(() {
                                                itemsPerPage = value ??
                                                    10; // Cập nhật số dòng mỗi trang
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              )
            ],
          )),
    );
  }

  Widget buildFilterDropdown<T>({
    required String label,
    required List<T> items,
    required T? selectedValue,
    required ValueChanged<T?> onChanged,
    String Function(T)? itemLabelBuilder, // <--- thêm hàm tùy chọn
  }) {
    return SizedBox(
      height: 60.h,
      child: Container(
        child: DropdownButtonHideUnderline(
          child: DropdownButton2<T>(
            isExpanded: true,
            hint: Text(
              label,
              style: TextStyle(
                fontSize: 4.sp,
              ),
            ),
            items: items.map((item) {
              final displayText = itemLabelBuilder != null
                  ? itemLabelBuilder(item)
                  : item.toString();

              return DropdownMenuItem<T>(
                value: item,
                child: Text(
                  displayText,
                  style: TextStyle(fontSize: 4.sp),
                ),
              );
            }).toList(),
            value: selectedValue,
            onChanged: onChanged,
            selectedItemBuilder: (context) {
              return items.map((item) {
                final displayText = itemLabelBuilder != null
                    ? itemLabelBuilder(item)
                    : item.toString();

                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    displayText,
                    style: TextStyle(fontSize: 4.sp),
                  ),
                );
              }).toList();
            },
            buttonStyleData: ButtonStyleData(
              height: 40.h,
              padding: EdgeInsets.symmetric(
                vertical: 0.h,
                horizontal: 10.w,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.r),
                border: Border.all(color: Color(0xe2707070)),
              ),
            ),
            dropdownStyleData: DropdownStyleData(
              maxHeight: 200.h,
              width: 80.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.r),
              ),
              elevation: 4,
            ),
            menuItemStyleData: MenuItemStyleData(
              height: 40.h,
              padding: EdgeInsets.symmetric(
                horizontal: 10.w,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildAreaFilter() {
    return SizedBox(
      height: 60.h, // Điều chỉnh chiều cao phù hợp
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: Color(0xe2707070)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          // Điều chỉnh padding ngang
          child: Row(
            children: [
              Text('Diện tích', style: TextStyle(fontSize: 4.sp)),
              SizedBox(
                width: 3.w,
              ),
              Expanded(
                child: RangeSlider(
                  values: selectedAreaRange,
                  min: minArea,
                  max: maxArea,
                  divisions: (maxArea - minArea).toInt(),
                  labels: RangeLabels(
                    '${selectedAreaRange.start.round()} m²',
                    '${selectedAreaRange.end.round()} m²',
                  ),
                  onChanged: (values) {
                    setState(() {
                      selectedAreaRange = values;
                    });

                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 300), () {
                      applyFilters();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
