import 'dart:async'; // Thêm import Timer
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/models/apartment.dart';
import 'package:do_an/src/models/contract_data.dart';
import 'package:do_an/src/resources/add_resident_screen_page.dart';
import 'package:do_an/src/resources/contract_form_page.dart';
import 'package:do_an/src/resources/contract_form_page_1.dart';
import 'package:do_an/src/resources/dialog/loading_dialog.dart';
import 'package:do_an/src/resources/dialog/msg_dialog.dart';
import 'package:do_an/src/resources/provider/contract_notifier_provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart'; // Thêm import shimmer

class ApartmentFilterPage extends StatefulWidget {
  const ApartmentFilterPage({Key? key}) : super(key: key);

  @override
  State<ApartmentFilterPage> createState() => _ApartmentFilterPageState();
}

class _ApartmentFilterPageState extends State<ApartmentFilterPage> {
  List<Apartment> allApartments = [];
  List<Apartment> filteredApartments = [];

  String? selectedBuilding;
  int? selectedFloor;
  String searchQuery = "";
  String? selectedContractStatus; // Biến lưu trạng thái hợp đồng ("isSale" hoặc "isRent")

  List<String> getAvailableBuildings() {
    return allApartments.map((a) => a.building).toSet().toList()..sort();
  }

  Timer? _debounce;

  late ContractNotifier contractNotifier;

  double minArea = 50;
  double maxArea = 120;
  RangeValues selectedAreaRange = const RangeValues(50, 120);

  double minFunction(double a, double b) => a < b ? a : b;
  double maxFunction(double a, double b) => a > b ? a : b;

  int currentPage = 1; // Trang hiện tại
  int itemsPerPage = 5; // Số lượng căn hộ mỗi trang
  List<Apartment> paginatedApartments = []; // Căn hộ hiển thị trên mỗi trang
  int totalPages = 0; // Tổng số trang
  List<int> pageNumbers = []; // Danh sách số trang cần hiển thị (1, 2, 3)

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

  void updatePaginatedApartments() {
    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    if (endIndex > filteredApartments.length) {
      endIndex = filteredApartments.length;
    }

    paginatedApartments = filteredApartments.sublist(startIndex, endIndex);
    totalPages = (filteredApartments.length / itemsPerPage).ceil();
    updatePageNumbers(); // Hàm này đã không gọi setState
  }

// Cập nhật danh sách các số trang (1, 2, 3, ...)
  void updatePageNumbers() {
    int startPage = currentPage - 1;
    if (startPage < 0) startPage = 0;

    // Hiển thị 3 trang trước và sau trang hiện tại
    pageNumbers = List.generate(3, (index) {
      int page = startPage + index;
      if (page < totalPages) {
        return page + 1;  // Trả về trang hợp lệ
      }
      return -1;  // Trả về giá trị không hợp lệ
    }).where((page) => page != -1).toList();  // Lọc bỏ giá trị -1

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

    // Lọc theo trạng thái hợp đồng
    if (selectedContractStatus == "isSale") {
      result = result.where((a) => a.isSale == true).toList();
    } else if (selectedContractStatus == "isRent") {
      result = result.where((a) => a.isRent == true).toList();
    }

    // Cập nhật các biến trước
    filteredApartments = result;
    currentPage = 1;
    updatePaginatedApartments(); // KHÔNG dùng setState bên trong hàm này nữa

    // Gọi setState sau khi các biến đã được cập nhật
    setState(() {});
  }

  List<int> getFloorsByBuilding(
      List<Apartment> apartments, String selectedBuilding) {
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

  Future<bool> deleteResidentAccount(String uid) async {
    try {
      final response = await http.post(
        Uri.parse("https://deleteresidentaccount-ttrkrlo35a-uc.a.run.app"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': uid}),
      );

      if (response.statusCode == 200) {
        print("✅ Xóa tài khoản $uid thành công.");
        return true;
      } else {
        print("❌ Lỗi khi xóa tài khoản $uid: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Exception khi gọi Cloud Function xóa user $uid: $e");
      return false;
    }
  }

  void showApartmentDialog(BuildContext context, Apartment apartment) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Phòng ${apartment.apartmentName}", textAlign: TextAlign.center, style: TextStyle(fontFamily: "Oswald", fontWeight: FontWeight.bold, fontSize: 8.sp),),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10.h,),
            Text('${apartment.building}', style: TextStyle(fontSize: 4.sp),),
            SizedBox(height: 30.h,),
            Text('Diện tích: ${apartment.area} m²', style: TextStyle(fontSize: 4.sp),),
            SizedBox(height: 30.h,),
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
            child: Text("Thuê", style: TextStyle(fontSize: 3.5.sp),),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ContractFormSalePage(
                      apartmentId: apartment.id, // 👈 truyền ID
                    ),
                  ));
            },
            child: Text("Mua", style: TextStyle(fontSize: 3.5.sp),),
          ),
        ],
      ),
    );
  }

  void showApartmentContractInfoDialog(BuildContext context, Apartment apartment, VoidCallback onRefresh) async {
    final apartmentDocRef = FirebaseFirestore.instance.collection("apartments").doc(apartment.id);
    final contractCollectionRef = apartmentDocRef.collection("contract");
    final billWaterCollectionRef = apartmentDocRef.collection("billWater");
    final residentsCollectionRef = FirebaseFirestore.instance.collection("residents"); // Reference đến collection "residents"
    final updateHistoryCollectionRef = apartmentDocRef.collection("updateHistory");
    try {
      // Lấy hợp đồng đầu tiên
      final contractSnapshot = await contractCollectionRef.get();

      if (contractSnapshot.docs.isEmpty) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Thông tin hợp đồng",style: TextStyle(fontSize: 4.sp, fontFamily: "Oswald", fontWeight: FontWeight.bold),),
            content: Text("Căn hộ này chưa có hợp đồng.", style: TextStyle(fontSize: 3.5.sp),),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Đóng", style: TextStyle(fontSize: 3.5.sp)))],
          ),
        );
        return;
      }

      final contractDoc = contractSnapshot.docs.first;
      final contract = ContractData.fromMap(contractDoc.data(), contractDoc.id, []);

      // Lấy hóa đơn nước đầu tiên
      final billWaterSnapshot = await billWaterCollectionRef.limit(1).get();
      String billWaterInfo = "Chưa có hóa đơn nước";

      final updateHistorySnapshot = await updateHistoryCollectionRef.limit(1).get();

      if (billWaterSnapshot.docs.isNotEmpty) {
        final billDoc = billWaterSnapshot.docs.first;
        // Xử lý thông tin hóa đơn nước nếu cần
        billWaterInfo = "Số tiền: ${billDoc['totalAmount']} VND";  // Giả sử bạn lưu tổng số tiền trong hóa đơn
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Center(
            child: Text(
              "Phòng ${contract.apartmentName}",
              style: TextStyle(fontSize: 7.sp, fontFamily: "Oswald", fontWeight: FontWeight.bold),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (apartment.isRent == true) ...[
                Text("Diện tích: ${contract.area} m²", style: TextStyle(fontSize: 3.5.sp)),
                SizedBox(height: 10.h),
                Text(
                  "Người đại diện: ${contract.representative?['fullName']?.trim().isNotEmpty == true ? contract.representative!['fullName'] : 'Không có'}",
                  style: TextStyle(fontSize: 3.5.sp),
                ),
                SizedBox(height: 10.h),
                Text("Số người ở: ${contract.numberOfResidents}", style: TextStyle(fontSize: 3.5.sp)),
                SizedBox(height: 10.h),
                Text(
                  'Đồ đạc, vận dụng đi kèm: ${contract.devices?.trim().isNotEmpty == true ? contract.devices : "Không có"}',
                  style: TextStyle(fontSize: 3.5.sp),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Quyền lợi chung: ${contract.benefit?.trim().isNotEmpty == true ? contract.benefit : "Không có"}',
                  style: TextStyle(fontSize: 3.5.sp),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Cam kết chung: ${contract.commit?.trim().isNotEmpty == true ? contract.commit : "Không có"}',
                  style: TextStyle(fontSize: 3.5.sp),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Nghĩa vụ chung: ${contract.duties?.trim().isNotEmpty == true ? contract.duties : "Không có"}',
                  style: TextStyle(fontSize: 3.5.sp),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Hạn chế: ${contract.limit?.trim().isNotEmpty == true ? contract.limit : "Không có"}',
                  style: TextStyle(fontSize: 3.5.sp),
                ),
                SizedBox(height: 10.h),
                Text('Mục đích ở: ${contract.purpose}', style: TextStyle(fontSize: 3.5.sp)),
                SizedBox(height: 10.h),
                Text("Tình trạng: ${apartment.isRent == true ? 'Đã được thuê' : 'Đã được mua'}", style: TextStyle(fontSize: 3.5.sp)),
                SizedBox(height: 10.h),
                Text('Thời gian kí: ${contract.createdAt}', style: TextStyle(fontSize: 3.5.sp)),
                SizedBox(height: 10.h),
                Text(
                  "Có hiệu lực từ: ${DateFormat('dd/MM/yyyy – HH:mm').format(contract.startDate)} đến ${contract.endDate != null ? DateFormat('dd/MM/yyyy – HH:mm').format(contract.endDate!) : '∞'}",
                  style: TextStyle(fontSize: 3.5.sp),
                ),
              ] else ...[
                Text("Diện tích: ${contract.area} m²", style: TextStyle(fontSize: 3.5.sp)),
                SizedBox(height: 10.h),
                Text(
                  "Người đại diện: ${contract.representative?['fullName']?.trim().isNotEmpty == true ? contract.representative!['fullName'] : 'Không có'}",
                  style: TextStyle(fontSize: 3.5.sp),
                ),
                SizedBox(height: 10.h),
                Text("Số người ở: ${contract.numberOfResidents}", style: TextStyle(fontSize: 3.5.sp)),
                SizedBox(height: 10.h),
                Text(
                  'Đồ đạc, vận dụng đi kèm: ${contract.devices?.trim().isNotEmpty == true ? contract.devices : "Không có"}',
                  style: TextStyle(fontSize: 3.5.sp),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Hạn chế: ${contract.limit?.trim().isNotEmpty == true ? contract.limit : "Không có"}',
                  style: TextStyle(fontSize: 3.5.sp),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Thời hạn thanh toán: ${contract.timepay != null ? DateFormat('dd/MM/yyyy – HH:mm').format(contract.timepay!) : "Không có"}',
                  style: TextStyle(fontSize: 3.5.sp),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Đợt thanh toán: ${contract.timepayattention?.trim().isNotEmpty == true ? contract.timepayattention : "Không có"}',
                  style: TextStyle(fontSize: 3.5.sp),
                ),
                SizedBox(height: 10.h),
                Text('Mục đích ở: ${contract.purpose}', style: TextStyle(fontSize: 3.5.sp)),
                SizedBox(height: 10.h),
                Text("Tình trạng: ${apartment.isRent == true ? 'Đã được thuê' : 'Đã được mua'}", style: TextStyle(fontSize: 3.5.sp)),
                SizedBox(height: 10.h),
                Text('Thời gian kí: ${contract.createdAt}', style: TextStyle(fontSize: 3.5.sp)),
                SizedBox(height: 10.h),
                Text(
                  "Có hiệu lực từ: ${DateFormat('dd/MM/yyyy – HH:mm').format(contract.startDate)} đến ${contract.endDate != null ? DateFormat('dd/MM/yyyy – HH:mm').format(contract.endDate!) : '∞'}",
                  style: TextStyle(fontSize: 3.5.sp),
                ),
              ],
            ],
          ),

          actions: [
            TextButton(
              onPressed: () async {
                final confirm = await showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Center(
                      child: Text(
                        "Xác nhận xóa",
                        style: TextStyle(fontSize: 6.sp, fontFamily: "Oswald", fontWeight: FontWeight.bold),
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
                          style: TextStyle(color: Colors.red, fontSize: 3.sp),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  try {
                    // Hiển thị dialog loading
                    // LoadingDialog.showLoadingDialog(context, "Đang tải ...");

                    // 1. Xóa hợp đồng
                    await contractDoc.reference.delete();

                    // 2. Xóa hóa đơn nước
                    final billWaterDoc = billWaterSnapshot.docs.isNotEmpty ? billWaterSnapshot.docs.first : null;
                    if (billWaterDoc != null) {
                      await billWaterDoc.reference.delete();
                    }

                    final updateHistoryDoc =
                    updateHistorySnapshot.docs.isNotEmpty ? updateHistorySnapshot.docs.first : null;
                    if (updateHistoryDoc != null) {
                      await updateHistoryDoc.reference.delete();
                    }

                    final residentsSnapshot = await residentsCollectionRef.where('apartmentId', isEqualTo: apartment.id).get();
                    for (var residentDoc in residentsSnapshot.docs) {
                      await residentDoc.reference.delete();
                    }

                    for (var residentDoc in residentsSnapshot.docs) {
                      final uid = residentDoc.id;
                      await deleteResidentAccount(uid); // Gọi hàm đã tách
                    }

                    // 3. Cập nhật trạng thái căn hộ
                    await apartmentDocRef.update({'isRent': false, 'isSale': false, 'residents': []});

                    // Đóng dialog loading
                    // LoadingDialog.hideLoadingDialog(context);

                    // Đóng dialog xác nhận
                    Navigator.pop(context);

                    // Làm mới giao diện
                    onRefresh();
                  } catch (e) {
                    // Ẩn dialog loading nếu xảy ra lỗi
                    // LoadingDialog.hideLoadingDialog(context);

                    // Hiển thị thông báo lỗi
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text("Lỗi", style: TextStyle(fontSize: 5.sp, fontWeight: FontWeight.bold)),
                        content: Text("Đã xảy ra lỗi: $e", style: TextStyle(fontSize: 4.sp)),
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
              },
              child: Text(
                "Xóa hợp đồng",
                style: TextStyle(color: Colors.red, fontSize: 3.sp),
              ),
            ),            TextButton(
              onPressed: () => showUpdateResidentsDialog(context, apartment, contract, onRefresh),
              child: Text("Cập nhật cư dân", style: TextStyle(fontSize: 3.sp)),
            ),
            TextButton(
              onPressed: () => _showUpdateHistoryDialog(context, updateHistoryCollectionRef),
              child: Text("Xem lịch sử thay đổi", style: TextStyle(fontSize: 3.sp)),
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
          content: Text("Không thể thực hiện thao tác xóa hợp đồng.", style: TextStyle(fontSize: 4.sp)),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Đóng", style: TextStyle(fontSize: 4.sp)))],
        ),
      );
    }
  }

  void _showUpdateHistoryDialog(BuildContext context, CollectionReference updateHistoryCollectionRef) async {
    try {
      // Lấy dữ liệu lịch sử từ Firestore
      final updateHistorySnapshot = await updateHistoryCollectionRef.orderBy("timestamp", descending: true).get();

      if (updateHistorySnapshot.docs.isEmpty) {
        // Hiển thị thông báo nếu không có lịch sử
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Lịch sử thay đổi", style: TextStyle(fontSize: 6.sp, fontWeight: FontWeight.bold)),
            content: Text("Chưa có gì thay đổi.", style: TextStyle(fontSize: 4.sp)),
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
          title: Center(child: Text("Lịch sử thay đổi", style: TextStyle(fontSize: 6.sp, fontWeight: FontWeight.bold),)),
          content: SizedBox(
            width: 80.w,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: updateHistorySnapshot.docs.length,
              itemBuilder: (context, index) {
                final history = updateHistorySnapshot.docs[index].data() as Map<String, dynamic>;
                final action = history['action'] ?? "Không xác định";
                final performedBy = history['performedBy'] ?? "Không xác định";
                final residentNames = (history['residentNames'] as List?)?.join(", ") ?? "Không có";
                final newRepresentative = history['newRepresentative'] != null
                    ? history['newRepresentative']['fullName']
                    : "Không có";
                final timestamp = (history['timestamp'] as Timestamp?)?.toDate();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hành động: $action", style: TextStyle(fontSize: 4.sp)),
                      Text("Thực hiện bởi: $performedBy", style: TextStyle(fontSize: 4.sp)),
                      Text("Cư dân liên quan: $residentNames", style: TextStyle(fontSize: 4.sp)),
                      Text("Người đại diện mới: $newRepresentative", style: TextStyle(fontSize: 4.sp)),
                      Text(
                        "Thời gian: ${timestamp != null ? DateFormat('dd/MM/yyyy – HH:mm').format(timestamp) : "Không xác định"}",
                        style: TextStyle(fontSize: 4.sp),
                      ),
                      Divider(
                        thickness: 0.1,       // Đặt độ dày của đường kẻ
                        indent: 10.0,         // Khoảng cách từ mép trái đến đường kẻ
                        endIndent: 10.0,      // Khoảng cách từ mép phải đến đường kẻ
                        color: Colors.black,   // Màu sắc của đường kẻ
                      ),
                    ],
                  ),
                );
              },
            ),
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
          content: Text("Không thể tải lịch sử thay đổi.", style: TextStyle(fontSize: 4.sp)),
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

  void showUpdateResidentsDialog(BuildContext context, Apartment apartment, ContractData contract, VoidCallback onRefresh) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Center(child: Text("Cập nhật thành viên",style: TextStyle(fontSize: 6.sp, fontFamily: "Oswald", fontWeight: FontWeight.bold)),),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                showAddResidentsFlow(context, apartment, contract, onRefresh);
              },
              child: Text("Thêm thành viên",style: TextStyle(fontSize: 3.5.sp)),
            ),
            SizedBox(height: 10.h,),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                showRemoveResidentsDialog(context, apartment, contract, onRefresh);
              },
              child: Text("Xóa thành viên",style: TextStyle(fontSize: 3.5.sp)),
            ),
          ],
        ),
      ),
    );
  }

  void showAddResidentsFlow(BuildContext context, Apartment apartment, ContractData contract, VoidCallback onRefresh) async {
    int maxCanAdd = 10 - contract.numberOfResidents;
    int? numberToAdd;

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Chọn số người cần thêm",style: TextStyle(fontSize: 6.sp, fontFamily: "Oswald", fontWeight: FontWeight.bold)),
              content: DropdownButtonHideUnderline(
                child: DropdownButton2<int>(
                  isExpanded: true,
                  hint: Text(
                    'Chọn số người',
                    style: TextStyle(
                      fontSize: 3.5.sp,
                      color: Colors.black,
                    ),
                  ),
                  value: numberToAdd, // Biến bạn đang dùng
                  items: List.generate(maxCanAdd, (i) => i + 1).map((e) {
                    return DropdownMenuItem<int>(
                      value: e,
                      child: Text(
                        '$e người',
                        style: TextStyle(fontSize: 3.sp),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => numberToAdd = value!),
                  buttonStyleData: ButtonStyleData(
                    height: 40.h,
                    width: double.infinity, // hoặc width: 40.w nếu bạn muốn cố định
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14.r),
                      color: const Color(0xFFF7FEFF),
                      border: Border.all(
                        color: Colors.grey,
                        width: 0.1.w,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                  ),
                  iconStyleData: IconStyleData(
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                    iconSize: 4.5.sp,
                  ),
                  dropdownStyleData: DropdownStyleData(
                    maxHeight: 150.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14.r),
                      color: const Color(0xFFF7FEFF),
                    ),
                  ),
                  menuItemStyleData: MenuItemStyleData(
                    height: 40.h,
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                  ),
                ),
              ),

              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text("Hủy",style: TextStyle(fontSize: 3.5.sp))),
                if (numberToAdd != null)
                  TextButton(
                    onPressed: () => Navigator.pop(context, numberToAdd),
                    child: Text("Tiếp tục",style: TextStyle(fontSize: 3.5.sp)),
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

  void showRemoveResidentsDialog(BuildContext context, Apartment apartment, ContractData contract, VoidCallback onRefresh) async {
    final contractRef = FirebaseFirestore.instance
        .collection("apartments")
        .doc(apartment.id)
        .collection("contract")
        .doc(contract.contractId);

    final residentsSnapshot = await FirebaseFirestore.instance
        .collection("residents")
        .where("apartmentId", isEqualTo: apartment.id)
        .get();

    if (residentsSnapshot.docs.isEmpty) {
      // Xử lý khi không có cư dân trong căn hộ này
      return;
    }

    final List<Map<String, dynamic>> residentList = residentsSnapshot.docs.map((doc) {
      final data = doc.data();
      final fullName = data["fullName"] ?? "Unknown";  // Tránh null cho fullName
      final isRepresentative = doc.id == contract.representative?["id"]; // So sánh theo id thay vì fullName

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
              title: Center(child: Text("Chọn cư dân cần xóa", style: TextStyle(fontSize: 6.sp, fontFamily: "Oswald", fontWeight: FontWeight.bold))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: residentList.map((r) {
                  return RadioListTile<String>(
                    title: Text(r["fullName"] + (r["isRepresentative"] ? " (Đại diện)" : ""), style: TextStyle(fontSize: 3.5.sp)),
                    value: r["id"],
                    groupValue: selectedIdToRemove,
                    onChanged: (value) => setState(() => selectedIdToRemove = value),
                  );
                }).toList(),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text("Hủy", style: TextStyle(fontSize: 3.5.sp))),
                TextButton(
                  onPressed: selectedIdToRemove == null ? null : () async {
                    Navigator.pop(context);

                    if (selectedIdToRemove == null) {
                      return;
                    }

                    LoadingDialog.showLoadingDialog(context, "Đang tải ...");

                    try {
                      final removedResident = residentList.firstWhere((r) => r["id"] == selectedIdToRemove);
                      final isRepresentative = removedResident["isRepresentative"];
                      final removedName = removedResident["fullName"];

                      if (isRepresentative) {
                        final others = residentList.where((r) => r["id"] != selectedIdToRemove).toList();

                        if (others.isEmpty) {
                          Navigator.pop(context); // Đóng Dialog Loading
                          MsgDialog.showMsgDialog(
                              context,
                              "Không thể xóa",
                              "Đây là người đại diện duy nhất và cũng là cư dân cuối cùng trong căn hộ. "
                                  "\nVui lòng xóa hợp đồng từ giao diện chính nếu muốn xóa toàn bộ."
                          );
                          return;
                        } else {
                          String? newRepId;
                          await showDialog(
                            context: context,
                            builder: (_) {
                              return StatefulBuilder(
                                builder: (context, setState) {
                                  return AlertDialog(
                                    title: Center(child: Text("Chọn người đại diện mới", style: TextStyle(fontFamily: "Oswald", fontWeight: FontWeight.bold, fontSize: 6.sp))),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: others.map((r) {
                                        return RadioListTile<String>(
                                          title: Text(r["fullName"], style: TextStyle(fontSize: 3.5.sp)),
                                          value: r["id"],
                                          groupValue: newRepId,
                                          onChanged: (value) => setState(() => newRepId = value),
                                        );
                                      }).toList(),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: Text("Hủy", style: TextStyle(fontSize: 3.5.sp))),
                                      TextButton(
                                        onPressed: newRepId == null ? null : () => Navigator.pop(context, newRepId),
                                        child: Text("Xác nhận", style: TextStyle(fontSize: 3.5.sp)),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ).then((newId) async {
                            if (newId != null) {
                              final newRepName = others.firstWhere((r) => r["id"] == newId)["fullName"];
                              final batch = FirebaseFirestore.instance.batch();
                              batch.update(contractRef, {
                                "representative": {"id": newId, "fullName": newRepName},
                                "numberOfResidents": FieldValue.increment(-1),
                              });
                              batch.delete(FirebaseFirestore.instance.collection("residents").doc(selectedIdToRemove));

                              final removedResidentSummary = {
                                'id': removedResident["id"],
                                'fullName': removedResident["fullName"],
                              };

                              batch.update(FirebaseFirestore.instance.collection("apartments").doc(apartment.id), {
                                "residents": FieldValue.arrayRemove([removedResidentSummary]),
                              });

                              batch.set(
                                FirebaseFirestore.instance.collection("apartments").doc(apartment.id).collection("updateHistory").doc(),
                                {
                                  "action": "Xóa cư dân & cập nhật người đại diện",
                                  "performedBy": "Admin",
                                  "residentNames": [removedName],
                                  "newRepresentative": {"id": newId, "fullName": newRepName},
                                  "timestamp": FieldValue.serverTimestamp(),
                                },
                              );

                              await deleteResidentAccount1(selectedIdToRemove!);
                              await batch.commit();
                              onRefresh();
                            }
                          });
                        }
                      } else {
                        final batch = FirebaseFirestore.instance.batch();
                        batch.update(contractRef, {
                          "numberOfResidents": FieldValue.increment(-1),
                        });
                        batch.delete(FirebaseFirestore.instance.collection("residents").doc(selectedIdToRemove));

                        final removedResidentSummary = {
                          'id': removedResident["id"],
                          'fullName': removedResident["fullName"],
                        };

                        batch.update(FirebaseFirestore.instance.collection("apartments").doc(apartment.id), {
                          "residents": FieldValue.arrayRemove([removedResidentSummary]),
                        });

                        batch.set(
                          FirebaseFirestore.instance.collection("apartments").doc(apartment.id).collection("updateHistory").doc(),
                          {
                            "action": "Xóa cư dân",
                            "performedBy": "Admin",
                            "residentNames": [removedName],
                            "timestamp": FieldValue.serverTimestamp(),
                          },
                        );

                        await deleteResidentAccount(selectedIdToRemove!);
                        await batch.commit();
                        onRefresh();
                      }

                      // Hiển thị thông báo thành công
                      MsgDialog.showMsgDialog(context, "Thành công", "Cư dân đã được xóa thành công!");
                    } catch (e) {

                      // Hiển thị thông báo lỗi
                      MsgDialog.showMsgDialog(context, "Lỗi", "Có lỗi xảy ra khi xóa cư dân. Vui lòng thử lại.");
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

  }  Future<void> deleteResidentAccount1(String uid) async {
    const functionUrl = 'https://deleteresidentaccount-ttrkrlo35a-uc.a.run.app';

    try {
      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': uid}),
      );

      if (response.statusCode == 200) {
        print("✅ Tài khoản đã bị xóa: ${response.body}");
      } else {
        print("❌ Lỗi khi xóa tài khoản: ${response.body}");
      }
    } catch (e) {
      print("❌ Exception khi gọi Cloud Function: $e");
    }
  }

  Future<void> fetchAreaRangeFromFirestore() async {
    final snapshot = await FirebaseFirestore.instance.collection('apartments').get();
    final areas = snapshot.docs
        .map((doc) => (doc['area'] as num).toDouble())
        .toList();

    if (areas.isNotEmpty) {
      final min = areas.reduce(minFunction);
      final max = areas.reduce(maxFunction);

      if (!mounted) return; // NGĂN gọi setState nếu widget đã bị dispose

      setState(() {
        minArea = min;
        maxArea = max;
        selectedAreaRange = RangeValues(minArea, maxArea);
      });
    }
  }

  Future<void> loadApartmentsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('apartments').get();
      List<Apartment> apartments = [];

      for (var doc in snapshot.docs) {
        try {
          apartments.add(Apartment.fromFirestore(doc));
        } catch (e) {
          print('❌ Error parsing document ${doc.id}: $e');
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
          filteredApartments = apartments; // Mặc định tất cả căn hộ
          updatePaginatedApartments(); // Cập nhật lại các căn hộ phân trang
        });
      }
    } catch (e) {
      print('Error loading apartments: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    loadApartmentsFromFirestore();
    fetchAreaRangeFromFirestore();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    contractNotifier = Provider.of<ContractNotifier>(context, listen: true);

    if (contractNotifier.contractCreated) {
      // Đợi sau build mới gọi reset để tránh lỗi
      WidgetsBinding.instance.addPostFrameCallback((_) async{
        await loadApartmentsFromFirestore();
        contractNotifier.reset();
      });
    }
  }

  @override
  void dispose(){
    _debounce?.cancel();
    super.dispose();

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7FEFF),
      body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: ConstrainedBox(constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height,),child: Padding(
                  padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 40.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Hợp đồng căn hộ",
                        style: TextStyle(
                          fontFamily: "Oswald",
                          fontWeight: FontWeight.w700,
                          fontSize: 12.sp,
                        ),
                      ),

                      SizedBox(height: 70.h),
                      SizedBox(
                          height: MediaQuery.of(context).size.height - 360.h ,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// Cột bên trái: Bộ lọc
                              Expanded(
                                child: SingleChildScrollView(
                                  child:  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: TextField(
                                          decoration: InputDecoration(
                                            labelText: "Tìm kiếm căn hộ",
                                            hintText: "Nhập tên căn hộ",
                                            prefixIcon: Icon(Icons.search),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(30.r),
                                            ),
                                          ),
                                          onChanged: _onSearchChanged,
                                        ),
                                      ),

                                      SizedBox(height: 30.h),

                                      // DropdownButton để lọc theo trạng thái hợp đồng
                                      buildFilterDropdown<String>(
                                        label: "Lọc theo trạng thái hợp đồng",
                                        items: ["isSale", "isRent"],
                                        selectedValue: selectedContractStatus,
                                        onChanged: (value) {
                                          setState(() {
                                            selectedContractStatus = value;
                                            applyFilters(); // Gọi hàm lọc khi thay đổi trạng thái hợp đồng
                                          });
                                        },
                                        itemLabelBuilder: (item) {
                                          if (item == "isSale") return "Đã được mua";
                                          if (item == "isRent") return "Đã được thuê";
                                          return item;
                                        },
                                      ),
                                      SizedBox(height: 20.h,),

                                      buildFilterDropdown<String>(
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
                                      SizedBox(height: 20.h),
                                      buildFilterDropdown<int>(
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
                                      SizedBox(height: 20.h),
                                      buildAreaFilter(),
                                    ],
                                  ),
                                ),
                              ),

                              // Vertical Divider
                              VerticalDivider(
                                color: Colors.grey, // Màu của đường ngăn cách
                                thickness: 0.2.w, // Độ dày của đường ngăn cách
                                width: 40.w, // Chiều rộng tổng thể của vùng ngăn cách (bao gồm cả padding nếu có)
                              ),

                              Expanded(
                                  child: Column(
                                    children: [
                                      allApartments.isEmpty
                                          ? Expanded(
                                          child: ListView.builder(
                                            itemCount: 6,
                                            itemBuilder: (context, index) => Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                              child: Shimmer.fromColors(
                                                baseColor: Colors.grey[300]!,
                                                highlightColor: Colors.grey[100]!,
                                                child: Container(
                                                  height: 80.h,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(8.r),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ))
                                          : (filteredApartments.isEmpty
                                          ? Center(
                                          child: Center(child: Text(
                                            'Không có căn hộ nào',
                                            style: TextStyle(fontSize: 5.sp, color: Colors.black54),
                                          ),)
                                      )
                                          :
                                      Expanded(
                                        child: ListView(
                                          children: [
                                            Column(
                                              children: [
                                                ...paginatedApartments.map((apartment) {
                                                  // Xác định trạng thái căn hộ
                                                  Icon statusIcon;
                                                  String statusText;

                                                  if (apartment.isRent == true) {
                                                    statusIcon = const Icon(Icons.vpn_key, color: Colors.orange);
                                                    statusText = "Đã được thuê";
                                                  } else if (apartment.isSale == true) {
                                                    statusIcon = const Icon(Icons.shopping_bag, color: Colors.green);
                                                    statusText = "Đã được mua";
                                                  } else {
                                                    statusIcon = const Icon(Icons.home_outlined, color: Colors.grey);
                                                    statusText = "Trống";
                                                  }

                                                  return FutureBuilder<QuerySnapshot>(
                                                    future: FirebaseFirestore.instance
                                                        .collection('apartments')
                                                        .doc(apartment.id)
                                                        .collection('contract')
                                                        .get(),
                                                    builder: (context, snapshot) {
                                                      String? representativeName;

                                                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                                                        final contractData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                                                        representativeName = contractData['representative']?['fullName'] ?? "Không có";
                                                      }

                                                      return Card(
                                                        color: const Color(0xFFF7FEFF),
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                                                        elevation: 2,
                                                        child: ListTile(
                                                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
                                                          subtitle: Row(
                                                            mainAxisAlignment: MainAxisAlignment.start,
                                                            children: [
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    Text(
                                                                      '${apartment.building} - ${apartment.apartmentName}',
                                                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                                                    ),
                                                                    SizedBox(height: 4.h),
                                                                    // Diện tích
                                                                    Text('Diện tích: ${apartment.area} m²'),
                                                                  ],
                                                                ),
                                                              ),
                                                              const Spacer(),
                                                              Column(
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      statusIcon,
                                                                      SizedBox(width: 4.w),
                                                                      Text(statusText, style: const TextStyle(color: Colors.black54)),
                                                                    ],
                                                                  ),

                                                                  // Đại diện nếu căn hộ không trống
                                                                  if (apartment.isRent == true || apartment.isSale == true) ...[
                                                                    SizedBox(height: 4.h),
                                                                    Text(
                                                                      'Người đại diện: $representativeName',
                                                                      style: const TextStyle(color: Colors.black87),
                                                                    ),
                                                                  ],
                                                                ],
                                                              )
                                                            ],
                                                          ),
                                                          onTap: () {
                                                            if (apartment.isRent == true || apartment.isSale == true) {
                                                              showApartmentContractInfoDialog(context, apartment, loadApartmentsFromFirestore);
                                                            } else {
                                                              showApartmentDialog(context, apartment);
                                                            }
                                                          },
                                                        ),
                                                      );
                                                    },
                                                  );
                                                }).toList(),

                                                // Row chứa các nút phân trang
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    // Nút về trang đầu
                                                    IconButton(
                                                      onPressed: currentPage > 1
                                                          ? () {
                                                        setState(() {
                                                          currentPage = 1;
                                                          updatePaginatedApartments();
                                                        });
                                                      }
                                                          : null,
                                                      icon: const Icon(Icons.first_page),
                                                    ),

                                                    // Nút về trang trước
                                                    IconButton(
                                                      onPressed: currentPage > 1
                                                          ? () {
                                                        setState(() {
                                                          currentPage--;
                                                          updatePaginatedApartments();
                                                        });
                                                      }
                                                          : null,
                                                      icon: const Icon(Icons.chevron_left),
                                                    ),

                                                    // Các nút số trang
                                                    ...pageNumbers.map((pageNum) {
                                                      return Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                                        child: ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: currentPage == pageNum ? Colors.blue : Colors.grey[300],
                                                            foregroundColor: currentPage == pageNum ? Colors.white : Colors.black,
                                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                          ),
                                                          onPressed: () {
                                                            setState(() {
                                                              currentPage = pageNum;
                                                              updatePaginatedApartments();
                                                            });
                                                          },
                                                          child: Text('$pageNum'),
                                                        ),
                                                      );
                                                    }).toList(),

                                                    // Nút sang trang sau
                                                    IconButton(
                                                      onPressed: currentPage < totalPages
                                                          ? () {
                                                        setState(() {
                                                          currentPage++;
                                                          updatePaginatedApartments();
                                                        });
                                                      }
                                                          : null,
                                                      icon: const Icon(Icons.chevron_right),
                                                    ),

                                                    // Nút sang trang cuối
                                                    IconButton(
                                                      onPressed: currentPage < totalPages
                                                          ? () {
                                                        setState(() {
                                                          currentPage = totalPages;
                                                          updatePaginatedApartments();
                                                        });
                                                      }
                                                          : null,
                                                      icon: const Icon(Icons.last_page),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      )
                                      ),
                                    ],
                                  )
                              )
                            ],
                          )),
                    ],
                  ),
                ))
                ,
              ),
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

    return Padding(
      padding: EdgeInsets.fromLTRB(0.w, 10.h, 0.w, 8.h),
      child: SizedBox(
        height: 60.h,
        child: Container(
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<T>(
              isExpanded: true,
              hint: Text(
                label,
                style: TextStyle(
                  color: Colors.black,
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
                  vertical: 2.h,
                  horizontal: 10.w ,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(color: Color(0xe2707070)),
                  color: Color(0xFFF7FEFF),
                ),
              ),
              dropdownStyleData: DropdownStyleData(
                maxHeight: 200.h,
                width: 142.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.r),
                  color: Color(0xFFF7FEFF),
                ),
                elevation: 4,
              ),
              menuItemStyleData: MenuItemStyleData(
                height: 40.h,
                padding: EdgeInsets.symmetric(
                  horizontal:  10.w ,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildAreaFilter() {
    return Padding(
      padding: EdgeInsets.fromLTRB(0.w, 10.h, 0.w, 8.h),
      // Điều chỉnh padding nếu cần
      child: SizedBox(
        height: 60.h, // Điều chỉnh chiều cao phù hợp
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: Color(0xe2707070)),
            color: Color(0xFFF7FEFF), // Màu nền nhẹ
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            // Điều chỉnh padding ngang
            child: Row(
              children: [
                Text('Diện tích',
                    style: TextStyle(fontSize: 4.sp)),
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
      ),
    );
  }
}
