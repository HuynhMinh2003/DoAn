import 'dart:async'; // Thêm import Timer
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/models/apartment.dart';
import 'package:do_an/src/resources/back_button.dart';
import 'package:do_an/src/resources/provider/contract_notifier_provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart'; // Thêm import shimmer
import 'package:excel/excel.dart' as ex;
import 'dart:html' as html;

class ApartmentListPage extends StatefulWidget {
  const ApartmentListPage({Key? key}) : super(key: key);

  @override
  State<ApartmentListPage> createState() => _ApartmentListPageState();
}

class _ApartmentListPageState extends State<ApartmentListPage> {
  List<Apartment> allApartments = [];
  List<Apartment> filteredApartments = [];

  String? selectedBuilding;
  int? selectedFloor;
  String searchQuery = "";
  String? selectedContractStatus;

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
    if (selectedContractStatus == "contract") {
      result = result.where((a) => a.isSale || a.isRent).toList(); // Gộp isSale và isRent
    } else if (selectedContractStatus == "empty") {
      result = result.where((a) => !a.isSale && !a.isRent).toList(); // Trạng thái trống
    }
      // Cập nhật các biến trước
    filteredApartments = result;
    currentPage = 1;
    updatePaginatedApartments(); // KHÔNG dùng setState bên trong hàm này nữa

    // Gọi setState sau khi các biến đã được cập nhật
    setState(() {});
  }

  void showApartmentDialog(BuildContext context, Apartment apartment, VoidCallback onRefresh) {
    final areaController = TextEditingController(text: apartment.area.toString());
    final rentController = TextEditingController(text: NumberFormat("#,###").format(apartment.rentPrice)); // Hiển thị có dấu phân cách
    final saleController = TextEditingController(text: NumberFormat("#,###").format(apartment.salePrice)); // Hiển thị có dấu phân cách
    final descriptionController = TextEditingController(text: apartment.description);

    bool isEditing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                "Thông tin phòng ${apartment.apartmentName}",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: "Oswald", fontWeight: FontWeight.bold, fontSize: 8.sp),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(' ${apartment.building}', style: TextStyle(fontSize: 4.sp)),
                    SizedBox(height: 10.h),
                    TextField(
                      controller: areaController,
                      enabled: isEditing,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 4.sp), // Cỡ chữ nội dung nhập
                      decoration: InputDecoration(
                        labelText: 'Diện tích (m²)',
                        labelStyle: TextStyle(fontSize: 4.sp), // Cỡ chữ label
                      ),
                    ),
                    TextField(
                      controller: rentController,
                      enabled: isEditing,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 4.sp),
                      decoration: InputDecoration(
                        labelText: 'Giá thuê (VNĐ)',
                        labelStyle: TextStyle(fontSize: 4.sp),
                      ),
                      onChanged: (value) {
                        if (isEditing) {
                          rentController.text = value.replaceAll(',', '');
                        }
                      },
                    ),
                    TextField(
                      controller: saleController,
                      enabled: isEditing,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 4.sp),
                      decoration: InputDecoration(
                        labelText: 'Giá mua (VNĐ)',
                        labelStyle: TextStyle(fontSize: 4.sp),
                      ),
                      onChanged: (value) {
                        if (isEditing) {
                          saleController.text = value.replaceAll(',', '');
                        }
                      },
                    ),
                    TextField(
                      controller: descriptionController,
                      enabled: isEditing,
                      style: TextStyle(fontSize: 4.sp),
                      decoration: InputDecoration(
                        labelText: 'Mô tả',
                        labelStyle: TextStyle(fontSize: 4.sp),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    // Kiểm tra giá trị của isRent và isSale
                    if (apartment.isRent == true || apartment.isSale == true) {
                      // Nếu là true thì hiển thị dialog không thể xóa
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Center(child: Text('Không thể xóa', style: TextStyle(fontFamily:"Oswald",fontSize: 7.sp,fontWeight: FontWeight.bold)),),
                          content: Text(
                            'Căn hộ này vẫn còn hợp đồng. Không thể xóa.',
                            style: TextStyle(fontSize: 4.sp),
                          ),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('OK', style: TextStyle(fontSize: 4.sp))),
                          ],
                        ),
                      );
                    } else {
                      // Nếu cả isRent và isSale đều là false, mới cho phép xóa
                      final confirm = await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Center(child: Text('Xác nhận xóa', style: TextStyle(fontFamily:"Oswald",fontSize: 7.sp,fontWeight: FontWeight.bold)),),
                          content: Text('Bạn có chắc muốn xóa căn hộ này?', style: TextStyle(fontSize: 4.sp)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Hủy', style: TextStyle(fontSize: 4.sp))),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Xóa', style: TextStyle(fontSize: 4.sp))),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        // Tiến hành xóa căn hộ
                        await FirebaseFirestore.instance.collection('apartments').doc(apartment.id).delete();
                        Navigator.pop(context);  // Quay lại trang trước
                        onRefresh();  // Cập nhật lại danh sách sau khi xóa
                      }
                    }
                  },
                  child: Text("Xóa", style: TextStyle(color: Colors.red, fontSize: 4.sp)),
                ),

                TextButton(
                  onPressed: () async {
                    if (isEditing) {
                      // Lưu cập nhật, chuyển giá thành dạng số sau khi chỉnh sửa
                      await FirebaseFirestore.instance.collection('apartments').doc(apartment.id).update({
                        'area': double.tryParse(areaController.text) ?? apartment.area,
                        'rentPrice': int.tryParse(rentController.text.replaceAll(',', '')) ?? apartment.rentPrice,
                        'salePrice': int.tryParse(saleController.text.replaceAll(',', '')) ?? apartment.salePrice,
                        'description': descriptionController.text,
                      });
                      Navigator.pop(context);
                      onRefresh();
                    } else {
                      // Bật chế độ sửa
                      setState(() {
                        isEditing = true;
                      });
                    }
                  },
                  child: Text(isEditing ? "Lưu" : "Sửa",style: TextStyle(fontSize: 4.sp)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context), // Nút Đóng thêm vào đây
                  child: Text("Đóng", style: TextStyle(fontSize: 4.sp),),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> fetchAreaRangeFromFirestore() async {
    final snapshot = await FirebaseFirestore.instance.collection('apartments').get();
    final areas = snapshot.docs
        .map((doc) => (doc['area'] as num).toDouble())
        .toList();

    if (areas.isNotEmpty) {
      final min = areas.reduce(minFunction);
      final max = areas.reduce(maxFunction);

      setState(() {
        minArea = min;
        maxArea = max;
        selectedAreaRange = RangeValues(minArea, maxArea);
      });
    }
  }

// Cập nhật danh sách căn hộ sau khi load từ Firestore
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

  Future<void> importApartmentsFromExcelWeb() async {
    final uploadInput = html.FileUploadInputElement()..accept = '.xlsx';
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final file = uploadInput.files!.first;
      final reader = html.FileReader();

      reader.readAsArrayBuffer(file);

      reader.onLoadEnd.listen((e) async {
        final bytes = reader.result as List<int>;
        final excel = ex.Excel.decodeBytes(bytes);
        final sheet = excel.tables[excel.tables.keys.first];
        if (sheet == null) return;

        for (int i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          final apartmentData = {
            'apartmentName': row[0]?.value.toString() ?? '',
            'area': double.tryParse(row[1]?.value.toString() ?? '0') ?? 0.0,
            'building': row[2]?.value.toString() ?? '',
            'description': row[3]?.value.toString() ?? '',
            'rentPrice': int.tryParse(row[4]?.value.toString() ?? '0') ?? 0,
            'salePrice': int.tryParse(row[5]?.value.toString() ?? '0') ?? 0,
            'isRent': false,
            'isSale': false,
            'residents': [],
          };

          await FirebaseFirestore.instance.collection('apartments').add(apartmentData);

        }
        loadApartmentsFromFirestore();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thêm căn hộ thành công!', style: TextStyle(fontSize: 4.sp),)),
        );

      });
    });
  }

  Future<void> exportApartmentsToExcel(List<Apartment> apartments) async {
    final excel = ex.Excel.createExcel(); // tạo file mới
    final sheet = excel['DanhSachCanHo']; // tạo sheet

    // Dòng tiêu đề (Header)
    final headers = [
      ex.TextCellValue('Tên căn hộ'),
      ex.TextCellValue('Diện tích'),
      ex.TextCellValue('Tòa nhà'),
      ex.TextCellValue('Mô tả'),
      ex.TextCellValue('Giá thuê'),
      ex.TextCellValue('Giá bán'),
    ];
    sheet.insertRowIterables(headers, 0); // Ghi dòng đầu tiên

    // Ghi từng dòng dữ liệu
    for (int i = 0; i < apartments.length; i++) {
      final apt = apartments[i];
      final row = [
        ex.TextCellValue(apt.apartmentName),
        ex.DoubleCellValue(apt.area as double),
        ex.TextCellValue(apt.building),
        ex.TextCellValue(apt.description),
        ex.IntCellValue(apt.rentPrice),
        ex.IntCellValue(apt.salePrice),
      ];
      sheet.insertRowIterables(row, i + 1);
    }

    // Xuất file
    final fileBytes = excel.encode();
    final blob = html.Blob([fileBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "DanhSachCanHo.xlsx")
      ..click();
    html.Url.revokeObjectUrl(url);
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
    // Gán chỉ 1 lần
    contractNotifier = Provider.of<ContractNotifier>(context, listen: false);
    // Reload nếu có hợp đồng mới
    if (contractNotifier.contractCreated) {
      loadApartmentsFromFirestore();
      contractNotifier.reset();
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
                child: Padding(
                  padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 40.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Danh sách căn hộ",
                        style: TextStyle(
                          fontFamily: "Oswald",
                          fontWeight: FontWeight.w700,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: 30.h,),
                      Row(
                        mainAxisSize:MainAxisSize.min,
                        children: [
                        ElevatedButton(
                        onPressed: importApartmentsFromExcelWeb,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add),
                            SizedBox(width: 5.w,),
                            Text('Thêm file', style: TextStyle(fontSize: 4.sp, fontWeight: FontWeight.bold, color: Colors.black),)
                          ],
                        ),
                      ),
                        SizedBox(width: 20.w,),
                        ElevatedButton(
                          onPressed: () => exportApartmentsToExcel(filteredApartments),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.upload),
                              SizedBox(width: 5.w,),
                              Text('Xuất file', style: TextStyle(fontSize: 4.sp, fontWeight: FontWeight.bold, color: Colors.black),)
                            ],
                          ),
                        ),],),
                      SizedBox(height: 40.h),
                      SizedBox(
                        height: MediaQuery.of(context).size.height - 360.h,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cột bên trái: Bộ lọc
                            Expanded(
                              child: Column(
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

                                  buildFilterDropdown<String>(
                                    label: "Lọc theo trạng thái hợp đồng",
                                    items: ["contract", "empty"], // "contract" cho hợp đồng, "empty" cho trống
                                    selectedValue: selectedContractStatus,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedContractStatus = value;
                                        applyFilters(); // Gọi hàm lọc khi thay đổi trạng thái hợp đồng
                                      });
                                    },
                                    itemLabelBuilder: (item) {
                                      if (item == "contract") return "Đã có hợp đồng"; // Gộp cả isSale và isRent
                                      if (item == "empty") return "Trống"; // Hiển thị căn hộ trống
                                      return item;
                                    },
                                  ),
                                  SizedBox(height: 20.h),
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
                            // Cột bên phải: Danh sách căn hộ
                            VerticalDivider(
                              color: Colors.grey, // Màu của đường ngăn cách
                              thickness: 0.2.w, // Độ dày của đường ngăn cách
                              width: 40.w, // Chiều rộng tổng thể của vùng ngăn cách (bao gồm cả padding nếu có)
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  allApartments.isEmpty
                                      ? Expanded(child: ListView.builder(
                                    itemCount: 5,
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
                                      : Column(
                                    children: [
                                      // Danh sách căn hộ trong khung cuộn với chiều cao cố định
                                      SizedBox(
                                        height: 430.h, // hoặc bất kỳ chiều cao nào bạn muốn
                                        child: ListView.builder(
                                          itemCount: paginatedApartments.length,
                                          itemBuilder: (context, index) {
                                            final apartment = paginatedApartments[index];
                                            Icon statusIcon;
                                            String statusText;

                                            if (apartment.isRent == true||apartment.isSale == true) {
                                              statusIcon = const Icon(Icons.assignment_turned_in, color: Colors.green);
                                              statusText = "Đã có chủ ";
                                            } else {
                                              statusIcon = const Icon(Icons.home_outlined, color: Colors.grey);
                                              statusText = "Trống";
                                            }

                                            return Card(
                                              color: const Color(0xFFF7FEFF),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                                              elevation: 2,
                                              child: ListTile(
                                                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
                                                title: Text(
                                                  '${apartment.building} - ${apartment.apartmentName}',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                subtitle: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(child: Text('Diện tích: ${apartment.area} m²')),

                                                    const Spacer(),

                                                    Row(
                                                      children: [
                                                        statusIcon,
                                                        SizedBox(width: 4.w),
                                                        Text(statusText, style: const TextStyle(color: Colors.black54)),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                onTap: () {
                                                  showApartmentDialog(context, apartment, () {
                                                    loadApartmentsFromFirestore();
                                                  });
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                      ),

                                      SizedBox(height: 20.h),

                                      // Phân trang cố định bên dưới
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
                                      )
                                    ],
                                  )
                                  ),
                                ],
                              ),
                            ),

                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
