import 'dart:async'; // Thêm import Timer
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/constants.dart';
import 'package:do_an/custom_paginated_table.dart';
import 'package:do_an/src/models/apartment.dart';
import 'package:do_an/src/models/contract_data.dart';
import 'package:do_an/src/resources/add_resident_screen_page.dart';
import 'package:do_an/src/resources/admin/contract_form_page.dart';
import 'package:do_an/src/resources/dialog/loading_dialog.dart';
import 'package:do_an/src/resources/dialog/msg_dialog.dart';
import 'package:do_an/src/resources/provider/contract_notifier_provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'ds_hopdong_canho_mobile_page.dart'
    if (dart.library.html) 'ds_hopdong_canho_web_page.dart';

class ContractListPage extends StatefulWidget {
  const ContractListPage({super.key});

  @override
  State<ContractListPage> createState() => _ContractListPageState();
}

class _ContractListPageState extends State<ContractListPage> {
  List<Apartment> allApartments = [];
  List<Apartment> filteredApartments = [];

  String? selectedBuilding;
  int? selectedFloor;
  String searchQuery = "";
  String? selectedContractStatus;

  Timer? _debounce;

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

  Future<void> showApartmentDialog(
      BuildContext context, Apartment apartment) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(
          "Phòng ${apartment.apartmentName}",
          textAlign: TextAlign.center,
          style: TextStyle(
              fontFamily: "Oswald",
              fontWeight: FontWeight.bold,
              fontSize: 7.sp),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 10.h,
            ),
            Text(
              '${apartment.building}',
              style: TextStyle(fontSize: 4.sp),
            ),
            SizedBox(
              height: 30.h,
            ),
            Text(
              'Diện tích: ${apartment.area} m²',
              style: TextStyle(fontSize: 4.sp),
            ),
            SizedBox(
              height: 30.h,
            ),
            Text(apartment.description, style: TextStyle(fontSize: 4.sp)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ContractFormRentPage(
                      apartmentId: apartment.id, // 👈 truyền ID
                    ),
                  ));
            },
            child: Text(
              "Thuê",
              style: TextStyle(fontSize: 3.5.sp),
            ),
          ),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Đóng", style: TextStyle(fontSize: 3.5.sp)))
        ],
      ),
    );
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

  Future<void> showApartmentContractInfoDialog(BuildContext context, Apartment apartment, Contract contract, VoidCallback onRefresh) async {
    final apartmentDocRef =
        FirebaseFirestore.instance.collection("apartments").doc(apartment.id);
    final residentsRef = FirebaseFirestore.instance
        .collection("residents"); // Reference đến collection "residents"
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

// ✅ Lấy document hợp đồng hợp lệ
      final contractDoc = contractQuery.docs.first;
      final contract = Contract.fromMap(contractDoc.data(), contractDoc.id, []);

// ✅ Tạo tham chiếu subcollection từ contractId
      final contractRef = FirebaseFirestore.instance
          .collection("contracts")
          .doc(contract.contractId);
      final updateHistoryCollectionRef =
          contractRef.collection("contractHistory");

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Center(
            child: Text(
              "Phòng ${contract.apartmentName}",
              style: TextStyle(
                  fontSize: 7.sp,
                  fontFamily: "Oswald",
                  fontWeight: FontWeight.bold),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Diện tích: ${contract.area} m²",
                  style: TextStyle(fontSize: 3.5.sp)),
              SizedBox(height: 10.h),
              Text(
                  "Người đại diện: ${contract.representative?['fullName'] ?? 'Không có'}",
                style: TextStyle(fontSize: 3.5.sp),
              ),
              SizedBox(height: 10.h),
              Text('Số người ở: ${contract.numberOfResidents}',
                  style: TextStyle(fontSize: 3.5.sp)),
              SizedBox(height: 10.h),
              Text('Mục đích ở: ${contract.purpose}',
                  style: TextStyle(fontSize: 3.5.sp)),
              SizedBox(height: 10.h),
              Text('Thời gian kí: ${DateFormat('dd/MM/yyyy - HH:mm').format(contract.createdAt)}',
                  style: TextStyle(fontSize: 3.5.sp)),
              SizedBox(height: 10.h),
              Text(
                "Có hiệu lực từ: ${DateFormat('dd/MM/yyyy').format(contract.startDate)} đến ${contract.endDate != null ? DateFormat('dd/MM/yyyy').format(contract.endDate!) : '∞'}",
                style: TextStyle(fontSize: 3.5.sp),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Center(
                      child: Text(
                        "Xác nhận xóa",
                        style: TextStyle(
                            fontSize: 7.sp,
                            fontFamily: "Oswald",
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    content: Text(
                      "Bạn có chắc chắn muốn xóa hợp đồng và hóa đơn nước của căn hộ này không?",
                      style: TextStyle(fontSize: 4.sp),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text("Hủy", style: TextStyle(fontSize: 4.sp)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          "Xóa",
                          style: TextStyle(color: Colors.red, fontSize: 4.sp),
                        ),
                      ),
                    ],
                  ),
                );

                if (!context.mounted || confirm != true) return;

                try {
                  // 1. Cập nhật trạng thái hợp đồng thành không còn hiệu lực
                  await contractDoc.reference.update({'isActive': false});

                  // 2. Ghi bản ghi lịch sử kết thúc hợp đồng
                  await updateHistoryCollectionRef.add({
                    'action': 'Kết thúc hợp đồng',
                    'performedBy': 'Admin',
                    'representativeName': contract.representative?['fullName'],
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  // 3. Cập nhật cư dân: isExit, lastUpdated và leftAt trong subcollection contractHistory
                  final residentsSnapshot = await residentsRef
                      .where('apartmentId', isEqualTo: apartment.id)
                      .get();
                  for (var residentDoc in residentsSnapshot.docs) {
                    // 3.1 update isExit và lastUpdated
                    await residentDoc.reference.update({
                      'isExit': true,
                      'leaveAt': Timestamp.now(),
                    });

                    // 3.2 update leftAt trong contractHistory mới nhất
                    final contractHistoryRef = residentDoc.reference.collection('contractHistory');

                    print('👉 Đang truy vấn contractHistory với contractId: ${apartment.currentContractId}');

                    final historySnap = await contractHistoryRef
                        .where('contractId', isEqualTo: apartment.currentContractId)
                        .orderBy('joinedAt', descending: true)
                        .limit(1)
                        .get();

                    print('🔍 Số lượng bản ghi tìm thấy: ${historySnap.docs.length}');

                    if (historySnap.docs.isNotEmpty) {
                      final historyDocId = historySnap.docs.first.id;
                      print('✅ Đã tìm thấy contractHistory docId: $historyDocId — sẽ cập nhật leftAt');

                      await historySnap.docs.first.reference.update({
                        'leftAt': Timestamp.now(),
                      });

                      print('✅ Đã cập nhật thành công leftAt tại docId: $historyDocId');
                    } else {
                      print('⚠️ Không tìm thấy contractHistory tương ứng để cập nhật leftAt');
                    }

                  }

                  // 4. Cập nhật lại trạng thái căn hộ
                  await apartmentDocRef.update({
                    'status': 'Trống',
                    'currentContractId': null,
                    'residents': [],
                  });

                  if (!context.mounted) return;
                  Navigator.pop(context); // Đóng dialog xác nhận
                  onRefresh();           // Làm mới giao diện

                } catch (e) {
                  if (!context.mounted) return;
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text("Lỗi",
                          style:
                          TextStyle(fontSize: 5.sp, fontWeight: FontWeight.bold)),
                      content: Text("Đã xảy ra lỗi: $e",
                          style: TextStyle(fontSize: 4.sp)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Đóng", style: TextStyle(fontSize: 4.sp)),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: Text(
                "Kết thúc hợp đồng",
                style: TextStyle(color: Colors.red, fontSize: 3.sp),
              ),
            ),
            TextButton(
              onPressed: () => showUpdateResidentsDialog(
                  context, apartment, contract, onRefresh),
              child: Text("Cập nhật cư dân", style: TextStyle(fontSize: 3.sp)),
            ),
            TextButton(
              onPressed: () =>
                  _showUpdateHistoryDialog(context, updateHistoryCollectionRef),
              child: Text("Xem lịch sử thay đổi",
                  style: TextStyle(fontSize: 3.sp)),
            ),
            TextButton(
              onPressed: () async {
                // 1. Chọn ngày mới
                final newEndDate = await showDatePicker(
                  context: context,
                  initialDate: contract.endDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (newEndDate == null) return;

                // 2. Hiển thị loading
                LoadingDialog.showLoadingDialog(context, "Đang gia hạn...");

                try {
                  // 3. Cập nhật endDate và lastUpdated
                  await contractDoc.reference.update({
                    'endDate': Timestamp.fromDate(newEndDate),
                    'lastUpdated': FieldValue.serverTimestamp(),
                  });

                  // 4. Ghi vào lịch sử
                  await updateHistoryCollectionRef.add({
                    'action': 'Gia hạn hợp đồng',
                    'performedBy': 'Admin',
                    'details': 'Gia hạn đến ${DateFormat('dd/MM/yyyy').format(newEndDate)}',
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  // 5. Ẩn loading
                  LoadingDialog.hideLoadingDialog(context);

                  // 6. Hiện dialog thành công
                  await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text("Thành công",
                          style: TextStyle(fontSize: 6.sp, fontWeight: FontWeight.bold)),
                      content: Text(
                        "Hợp đồng đã được gia hạn đến ${DateFormat('dd/MM/yyyy').format(newEndDate)}.",
                        style: TextStyle(fontSize: 4.sp),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Đóng", style: TextStyle(fontSize: 4.sp)),
                        ),
                      ],
                    ),
                  );

                  // 7. Đóng dialog gốc và làm mới UI
                  if (context.mounted) {
                    Navigator.pop(context);
                    onRefresh();
                  }
                } catch (e) {
                  // ẩn loading rồi show lỗi
                  LoadingDialog.hideLoadingDialog(context);
                  if (!context.mounted) return;
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text("Lỗi",
                          style: TextStyle(fontSize: 5.sp, fontWeight: FontWeight.bold)),
                      content: Text("Không thể gia hạn hợp đồng: $e",
                          style: TextStyle(fontSize: 4.sp)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Đóng", style: TextStyle(fontSize: 4.sp)),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: Text("Gia hạn hợp đồng", style: TextStyle(fontSize: 3.sp)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Đóng", style: TextStyle(fontSize: 3.sp)),
            ),
          ],
        ),
      );
    } catch (e) {
      print("❌ Lỗi khi xóa hợp đồng: $e");
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Lỗi", style: TextStyle(fontSize: 6.sp)),
          content: Text("Không thể thực hiện thao tác xóa hợp đồng.",
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

  void showUpdateResidentsDialog(BuildContext context, Apartment apartment, Contract contract, VoidCallback onRefresh) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Center(
          child: Text("Cập nhật thành viên",
              style: TextStyle(
                  fontSize: 6.sp,
                  fontFamily: "Oswald",
                  fontWeight: FontWeight.bold)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                showAddResidentsFlow(context, apartment, contract, onRefresh);
              },
              child:
                  Text("Thêm thành viên", style: TextStyle(fontSize: 3.5.sp)),
            ),
            SizedBox(
              height: 10.h,
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                showRemoveResidentsDialog(
                    context, apartment, contract, onRefresh);
              },
              child: Text("Xóa thành viên", style: TextStyle(fontSize: 3.5.sp)),
            ),
          ],
        ),
      ),
    );
  }

  void showAddResidentsFlow(BuildContext context, Apartment apartment, Contract contract, VoidCallback onRefresh) async {
    int maxCanAdd = 10 - contract.numberOfResidents;
    int? numberToAdd;

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Chọn số người cần thêm",
                  style: TextStyle(
                      fontSize: 6.sp,
                      fontFamily: "Oswald",
                      fontWeight: FontWeight.bold)),
              content: DropdownButtonHideUnderline(
                child: DropdownButton2<int>(
                  isExpanded: true,
                  hint: Text(
                    'Chọn số người',
                    style: TextStyle(
                      fontSize: 3.5.sp,
                      color: Colors.white,
                    ),
                  ),
                  value: numberToAdd,
                  // Biến bạn đang dùng
                  items: List.generate(maxCanAdd, (i) => i + 1).map((e) {
                    return DropdownMenuItem<int>(
                      value: e,
                      child: Text(
                        '$e người',
                        style: TextStyle(fontSize: 4.sp),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => numberToAdd = value!),
                  buttonStyleData: ButtonStyleData(
                    height: 40.h,
                    width: double.infinity,
                    // hoặc width: 40.w nếu bạn muốn cố định
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14.r),
                      color: bgColor,
                      border: Border.all(
                        color: bgColor,
                        width: 0.1.w,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                  ),
                  iconStyleData: IconStyleData(
                    icon:
                        const Icon(Icons.arrow_drop_down, color: Colors.white),
                    iconSize: 4.5.sp,
                  ),
                  dropdownStyleData: DropdownStyleData(
                    maxHeight: 150.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14.r),
                      color: bgColor,
                    ),
                  ),
                  menuItemStyleData: MenuItemStyleData(
                    height: 40.h,
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Hủy", style: TextStyle(fontSize: 3.5.sp))),
                if (numberToAdd != null)
                  TextButton(
                    onPressed: () => Navigator.pop(context, numberToAdd),
                    child: Text("Tiếp tục", style: TextStyle(fontSize: 3.5.sp)),
                  ),
              ],
            );
          },
        );
      },
    ).then((value) {
      if (value != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddResidentsScreen(
              count: value,
              apartment: apartment,
              contract: contract,
              onComplete: onRefresh,
            ),
          ),
        );
      }
    });
  }

  void showRemoveResidentsDialog(BuildContext context, Apartment apartment, Contract contract, VoidCallback onRefresh) async {
    final apartmentDocRef =
        FirebaseFirestore.instance.collection("apartments").doc(apartment.id);

    try {
      // Lấy document apartment
      final apartmentDoc = await apartmentDocRef.get();

      if (!apartmentDoc.exists) {
        print("Căn hộ không tồn tại.");
        return;
      }

      final currentContractId = apartmentDoc.data()?["currentContractId"];

      if (currentContractId == null || currentContractId.isEmpty) {
        print("Không có currentContractId.");
        return;
      }

      final contractDocRef = FirebaseFirestore.instance
          .collection("contracts")
          .doc(currentContractId);

      final contractSnapshot = await contractDocRef.get();

      if (!contractSnapshot.exists) {
        print("Hợp đồng không tồn tại.");
        return;
      }

      final residentsSnapshot = await FirebaseFirestore.instance
          .collection("residents")
          .where("apartmentId", isEqualTo: apartment.id)
          .where("isExit", isEqualTo: false)
          .get();

      if (residentsSnapshot.docs.isEmpty) {
        // Xử lý khi không có cư dân trong căn hộ này
        return;
      }

      final List<Map<String, dynamic>> residentList =
          residentsSnapshot.docs.map((doc) {
        final data = doc.data();
        final fullName =
            data["fullName"] ?? "Unknown"; // Tránh null cho fullName
        final isRepresentative = doc.id ==
            contract.representative?["id"]; // So sánh theo id thay vì fullName

        return {
          "id": doc.id,
          "fullName": fullName,
          "isRepresentative": isRepresentative,
        };
      }).toList();

      String? selectedIdToRemove;

      await showDialog(
        context: context,
        builder: (_) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Center(
                    child: Text("Chọn cư dân cần xóa",
                        style: TextStyle(
                            fontSize: 6.sp,
                            fontFamily: "Oswald",
                            fontWeight: FontWeight.bold))),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: residentList.map((r) {
                    return RadioListTile<String>(
                      title: Text(
                          r["fullName"] +
                              (r["isRepresentative"] ? " (Đại diện)" : ""),
                          style: TextStyle(fontSize: 3.5.sp)),
                      value: r["id"],
                      groupValue: selectedIdToRemove,
                      onChanged: (value) =>
                          setState(() => selectedIdToRemove = value),
                    );
                  }).toList(),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Hủy", style: TextStyle(fontSize: 3.5.sp))),
                  TextButton(
                    onPressed: selectedIdToRemove == null
                        ? null
                        : () async {
                            Navigator.pop(context);

                            if (selectedIdToRemove == null) {
                              return;
                            }

                            // LoadingDialog.showLoadingDialog(context, "Đang tải ...");

                            try {
                              final removedResident = residentList.firstWhere(
                                  (r) => r["id"] == selectedIdToRemove);
                              final isRepresentative =
                                  removedResident["isRepresentative"];
                              final removedName = removedResident["fullName"];

                              if (isRepresentative) {
                                final others = residentList
                                    .where((r) => r["id"] != selectedIdToRemove)
                                    .toList();

                                if (others.isEmpty) {
                                  // Navigator.pop(context); // Đóng Dialog Loading
                                  MsgDialog.showMsgDialog(
                                      context,
                                      "Không thể xóa",
                                      "Đây là người đại diện duy nhất và cũng là cư dân cuối cùng trong căn hộ. "
                                          "\nVui lòng xóa hợp đồng từ giao diện chính nếu muốn xóa toàn bộ.");
                                  return;
                                } else {
                                  String? newRepId;
                                  await showDialog(
                                    context: context,
                                    builder: (_) {
                                      return StatefulBuilder(
                                        builder: (context, setState) {
                                          return AlertDialog(
                                            title: Center(
                                                child: Text(
                                                    "Chọn người đại diện mới",
                                                    style: TextStyle(
                                                        fontFamily: "Oswald",
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 6.sp))),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: others.map((r) {
                                                return RadioListTile<String>(
                                                  title: Text(r["fullName"],
                                                      style: TextStyle(
                                                          fontSize: 3.5.sp)),
                                                  value: r["id"],
                                                  groupValue: newRepId,
                                                  onChanged: (value) =>
                                                      setState(() =>
                                                          newRepId = value),
                                                );
                                              }).toList(),
                                            ),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: Text("Hủy",
                                                      style: TextStyle(
                                                          fontSize: 3.5.sp))),
                                              TextButton(
                                                onPressed: newRepId == null
                                                    ? null
                                                    : () => Navigator.pop(
                                                        context, newRepId),
                                                child: Text("Xác nhận",
                                                    style: TextStyle(
                                                        fontSize: 3.5.sp)),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ).then((newId) async {
                                    if (newId != null) {
                                      final newRepName = others.firstWhere(
                                          (r) => r["id"] == newId)["fullName"];
                                      final batch =
                                          FirebaseFirestore.instance.batch();
                                      batch.update(contractDocRef, {
                                        "representative": {
                                          "id": newId,
                                          "fullName": newRepName
                                        },
                                        "numberOfResidents":
                                            FieldValue.increment(-1),
                                      });
                                      batch.update(
                                        FirebaseFirestore.instance
                                            .collection("residents")
                                            .doc(selectedIdToRemove),
                                        {
                                          'isExit': true,
                                          'leaveAt': Timestamp.now(),
                                        },
                                      );
                                      // 1. Tạo reference tới subcollection contractHistory của resident
                                      final residentHistoryRef = FirebaseFirestore.instance
                                          .collection("residents")
                                          .doc(selectedIdToRemove)
                                          .collection("contractHistory");

                                      // 2. Query: lọc theo contractId, sắp xếp joinedAt mới nhất trước, limit 1
                                      final residentHistorySnapshot = await residentHistoryRef
                                          .where("contractId", isEqualTo: currentContractId)
                                          .orderBy("joinedAt", descending: true)  // mới nhất → cũ nhất
                                          .limit(1)                                // chỉ 1 bản ghi
                                          .get();

                                      // 3. Nếu có, cập nhật leftAt cho bản mới nhất đó
                                      if (residentHistorySnapshot.docs.isNotEmpty) {
                                        final latestDocRef = residentHistorySnapshot.docs.first.reference;
                                        await latestDocRef.update({
                                          "leftAt": Timestamp.now(),
                                        });
                                      }


                                      final removedResidentSummary = {
                                        'id': removedResident["id"],
                                        'fullName': removedResident["fullName"],
                                      };

                                      batch.update(
                                          FirebaseFirestore.instance
                                              .collection("apartments")
                                              .doc(apartment.id),
                                          {
                                            "residents": FieldValue.arrayRemove(
                                                [removedResidentSummary]),
                                          });

                                      batch.set(
                                        FirebaseFirestore.instance
                                            .collection("contracts")
                                            .doc(contract.contractId)
                                            .collection("contractHistory")
                                            .doc(),
                                        {
                                          "action":
                                              "Xóa cư dân & cập nhật người đại diện",
                                          "performedBy": "Admin",
                                          "residentNames": [removedName],
                                          "newRepresentative": {
                                            "id": newId,
                                            "fullName": newRepName
                                          },
                                          "timestamp":
                                              FieldValue.serverTimestamp(),
                                        },
                                      );

                                      // await deleteResidentAccount1(selectedIdToRemove!);
                                      await batch.commit();
                                      onRefresh();
                                      Navigator.pop(context);
                                    }
                                  });
                                }
                              } else {
                                final batch =
                                    FirebaseFirestore.instance.batch();
                                batch.update(contractDocRef, {
                                  "numberOfResidents": FieldValue.increment(-1),
                                });
                                batch.update(
                                  FirebaseFirestore.instance
                                      .collection("residents")
                                      .doc(selectedIdToRemove),
                                  {
                                    'isExit': true,
                                    'leaveAt': Timestamp.now(),
                                  },
                                );
                                // Cập nhật leftAt trong contractHistory của resident (nếu tồn tại entry có contractId khớp)
                                final residentHistoryRef = FirebaseFirestore
                                    .instance
                                    .collection("residents")
                                    .doc(selectedIdToRemove)
                                    .collection("contractHistory");

                                final residentHistorySnapshot =
                                    await residentHistoryRef
                                        .where("contractId",
                                            isEqualTo: currentContractId)
                                        .limit(1)
                                        .get();

                                if (residentHistorySnapshot.docs.isNotEmpty) {
                                  final docId =
                                      residentHistorySnapshot.docs.first.id;
                                  batch.update(residentHistoryRef.doc(docId), {
                                    "leftAt": Timestamp.now(),
                                  });
                                }

                                final removedResidentSummary = {
                                  'id': removedResident["id"],
                                  'fullName': removedResident["fullName"],
                                };

                                batch.update(
                                    FirebaseFirestore.instance
                                        .collection("apartments")
                                        .doc(apartment.id),
                                    {
                                      "residents": FieldValue.arrayRemove(
                                          [removedResidentSummary]),
                                    });

                                batch.set(
                                  FirebaseFirestore.instance
                                      .collection("contracts")
                                      .doc(contract.contractId)
                                      .collection("contractHistory")
                                      .doc(),
                                  {
                                    "action": "Xóa cư dân",
                                    "performedBy": "Admin",
                                    "residentNames": [removedName],
                                    "timestamp": FieldValue.serverTimestamp(),
                                  },
                                );

                                await batch.commit();
                                onRefresh();
                                Navigator.pop(context);
                              }

                              // Hiển thị thông báo thành công
                              MsgDialog.showMsgDialog(context, "Thành công",
                                  "Cư dân đã được xóa thành công!");
                            } catch (e) {
                              // Hiển thị thông báo lỗi
                              MsgDialog.showMsgDialog(context, "Lỗi",
                                  "Có lỗi xảy ra khi xóa cư dân. Vui lòng thử lại.");
                            }
                          },
                    child: Text("Xóa"),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      print("Lỗi khi truy vấn hợp đồng: $e");
    }
  }

  void _showUpdateHistoryDialog(BuildContext context, CollectionReference updateHistoryCollectionRef) async {
    try {
      // Lấy dữ liệu lịch sử từ Firestore
      final updateHistorySnapshot = await updateHistoryCollectionRef
          .orderBy("timestamp", descending: true)
          .get();

      if (updateHistorySnapshot.docs.isEmpty) {
        // Hiển thị thông báo nếu không có lịch sử
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Lịch sử thay đổi",
                style: TextStyle(fontSize: 6.sp, fontWeight: FontWeight.bold)),
            content:
                Text("Chưa có gì thay đổi.", style: TextStyle(fontSize: 4.sp)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Đóng", style: TextStyle(fontSize: 4.sp)),
              ),
            ],
          ),
        );
        return;
      }

      // Hiển thị danh sách lịch sử
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Center(
              child: Text(
            "Lịch sử thay đổi",
            style: TextStyle(fontSize: 6.sp, fontWeight: FontWeight.bold),
          )),
          content: SizedBox(
            width: 80.w,
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: updateHistorySnapshot.docs.length,
                itemBuilder: (context, index) {
                  final history = updateHistorySnapshot.docs[index].data()
                      as Map<String, dynamic>;
                  final action = history['action'];
                  final performedBy = history['performedBy'];
                  final representativeName = history['representativeName'];
                  final residentNamesList = history['residents'] as List?;
                  final newRepresentative =
                      history['newRepresentative']?['fullName'];
                  final timestamp =
                      (history['timestamp'] as Timestamp?)?.toDate();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (action != null)
                          Text("Hành động: $action",
                              style: TextStyle(fontSize: 4.sp)),
                        if (performedBy != null)
                          Text("Thực hiện bởi: $performedBy",
                              style: TextStyle(fontSize: 4.sp)),
                        if (residentNamesList != null &&
                            residentNamesList.isNotEmpty)
                          Text(
                              "Cư dân liên quan: ${residentNamesList.join(", ")}",
                              style: TextStyle(fontSize: 4.sp)),
                        if (newRepresentative != null)
                          Text("Người đại diện mới: $newRepresentative",
                              style: TextStyle(fontSize: 4.sp)),
                        if (representativeName != null)
                          Text("Người đại diện: $representativeName",
                              style: TextStyle(fontSize: 4.sp)),
                        if (timestamp != null)
                          Text(
                            "Thời gian: ${DateFormat('dd/MM/yyyy – HH:mm').format(timestamp)}",
                            style: TextStyle(fontSize: 4.sp),
                          ),
                        Divider(
                          thickness: 0.1,
                          indent: 10.0,
                          endIndent: 10.0,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  );
                }),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Đóng", style: TextStyle(fontSize: 4.sp)),
            ),
          ],
        ),
      );
    } catch (e) {
      print("❌ Lỗi khi hiển thị lịch sử thay đổi: $e");
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Lỗi", style: TextStyle(fontSize: 6.sp)),
          content: Text("Không thể tải lịch sử thay đổi.",
              style: TextStyle(fontSize: 4.sp)),
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
                            "Quản lý hợp đồng",
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
                          flex: 2,
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
                              onPressed: () =>
                                  exportContractApartmentsToExcel(filteredApartments),
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.upload),
                                  SizedBox(width: 5.w),
                                  Text(
                                    'Xuất file',
                                    style: TextStyle(
                                        fontSize: 4.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white
                                    ),
                                  ),
                                ],
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
                                                    icon: Icon(
                                                      (isRented && hasContract) ? Icons.info_outline : Icons.add,
                                                      color: (isRented && hasContract) ? Colors.white : Colors.green,
                                                    ),
                                                    onPressed: () async {
                                                      if (_isDialogShowing)
                                                        return;
                                                      _isDialogShowing = true;

                                                      try {
                                                        if (isRented &&
                                                            hasContract) {
                                                          final query = await FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                  'contracts')
                                                              .where(
                                                                  'apartmentDocId',
                                                                  isEqualTo:
                                                                      apartment
                                                                          .id)
                                                              .where('isActive',
                                                                  isEqualTo:
                                                                      true)
                                                              .limit(1)
                                                              .get();

                                                          if (query.docs
                                                              .isNotEmpty) {
                                                            final contract =
                                                                Contract
                                                                    .fromMap(
                                                              query.docs.first
                                                                  .data(),
                                                              query.docs.first
                                                                  .id,
                                                              [],
                                                            );

                                                            // ĐẢM BẢO AWAIT ĐÂY
                                                            await showApartmentContractInfoDialog(
                                                              context,
                                                              apartment,
                                                              contract,
                                                              loadApartmentsFromFirestore,
                                                            );
                                                          }
                                                        } else {
                                                          // ĐẢM BẢO AWAIT ĐÂY
                                                          await showApartmentDialog(
                                                              context,
                                                              apartment);
                                                        }
                                                      } catch (e) {
                                                        print(
                                                            'Lỗi hiển thị dialog: $e');
                                                      } finally {
                                                        _isDialogShowing =
                                                            false;
                                                      }
                                                    },
                                                  )
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
