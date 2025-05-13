import 'dart:async'; // Thêm import Timer
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/models/apartment.dart';
import 'package:do_an/src/resources/dialog/loading_dialog.dart';
import 'package:do_an/src/resources/provider/contract_notifier_provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'ds_canho_mobile_page.dart' if (dart.library.html) 'ds_canho_web_page.dart';


class ApartmentListPage extends StatefulWidget {
  const ApartmentListPage({super.key});

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
        return page + 1;  // Trả về trang hợp lệ
      }
      return -1;  // Trả về giá trị không hợp lệ
    }).where((page) => page != -1).toList();  // Lọc bỏ giá trị -1
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
      body: SafeArea(
          child: Stack(
            children: [
          SingleChildScrollView(
          child: ConstrainedBox(
          constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
      ),
      child: Padding(
        padding: EdgeInsets.only(left: 10.w, right: 10.w, top: 40.h, bottom: 10.h),
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
                    "Danh sách căn hộ",
                    style: TextStyle(
                      fontSize: 6.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 20.w), // Khoảng cách giữa tiêu đề và tìm kiếm

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
                SizedBox(width: 20.w), // Khoảng cách giữa tìm kiếm và nút

                // Nút Thêm file
                Flexible(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: () => importApartmentsFromExcel,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add),
                        SizedBox(width: 5.w),
                        Text(
                          'Thêm file',
                          style: TextStyle(
                            fontSize: 4.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 10.w), // Khoảng cách giữa hai nút

                // Nút Xuất file
                Flexible(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: () => exportApartmentsToExcel(filteredApartments),
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 40.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: buildFilterDropdown<String>(
                  label: "Trạng thái",
                  items: ["contract", "empty"],
                  selectedValue: selectedContractStatus,
                  onChanged: (value) {
                    setState(() {
                      selectedContractStatus = value;
                      applyFilters();
                    });
                  },
                  itemLabelBuilder: (item) {
                    if (item == "contract") return "Đã có hợp đồng";
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
            SizedBox(height: 10.h,),
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
                              style: TextStyle(fontSize: 4.sp, color: Colors.black54),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth, // Đặt chiều rộng tối thiểu bằng chiều rộng cha
                                maxWidth: constraints.maxWidth, // Đặt chiều rộng tối đa bằng chiều rộng cha
                              ),
                              child: PaginatedDataTable(
                                columns: [
                                  DataColumn(label: Text("Tòa", style: TextStyle(fontSize: 4.sp))),
                                  DataColumn(label: Text("Tên căn hộ", style: TextStyle(fontSize: 4.sp))),
                                  DataColumn(label: Text("Tầng", style: TextStyle(fontSize: 4.sp))),
                                  DataColumn(label: Text("Diện tích", style: TextStyle(fontSize: 4.sp))),
                                  DataColumn(label: Text("Mô tả", style: TextStyle(fontSize: 4.sp))),
                                  DataColumn(label: Text("Trạng thái dịch vụ", style: TextStyle(fontSize: 4.sp))),
                                  DataColumn(label: Text("Hành động", style: TextStyle(fontSize: 4.sp))),
                                ],
                                rowsPerPage: itemsPerPage,
                                source: _ApartmentsDataSource(paginatedApartments, context, loadApartmentsFromFirestore),
                                showFirstLastButtons: false,
                                onPageChanged: (page) {
                                  setState(() {
                                    currentPage = (page ~/ itemsPerPage) + 1;
                                    updatePaginatedApartments();
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      // Phân trang
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: currentPage > 1
                                ? () {
                              setState(() {
                                currentPage = 1;
                                updatePaginatedApartments();
                              });
                            }
                                : null,
                            icon: Icon(Icons.first_page),
                          ),
                          IconButton(
                            onPressed: currentPage > 1
                                ? () {
                              setState(() {
                                currentPage--;
                                updatePaginatedApartments();
                              });
                            }
                                : null,
                            icon: Icon(Icons.chevron_left),
                          ),
                          Text("Trang $currentPage / $totalPages"),
                          IconButton(
                            onPressed: currentPage < totalPages
                                ? () {
                              setState(() {
                                currentPage++;
                                updatePaginatedApartments();
                              });
                            }
                                : null,
                            icon: Icon(Icons.chevron_right),
                          ),
                          IconButton(
                            onPressed: currentPage < totalPages
                                ? () {
                              setState(() {
                                currentPage = totalPages;
                                updatePaginatedApartments();
                              });
                            }
                                : null,
                            icon: Icon(Icons.last_page),
                          ),
                        ],
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
                horizontal: 10.w ,
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
                horizontal:  10.w ,
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
    );
  }
}

// Lớp hỗ trợ cho PaginatedDataTable
class _ApartmentsDataSource extends DataTableSource {
  final List<Apartment> apartments;
  final BuildContext context; // Thêm context
  final VoidCallback onRefresh; // Hàm tải lại dữ liệu

  _ApartmentsDataSource(this.apartments, this.context, this.onRefresh);

  @override
  DataRow? getRow(int index) {
    if (index >= apartments.length) return null;
    final apartment = apartments[index];
    final status = apartment.isRent
        ? 'Đã thuê'
        : (apartment.isSale ? "Đã bán" : "Chưa kích hoạt");

    return DataRow(cells: [
      DataCell(Text(apartment.building,style: TextStyle(fontSize: 4.sp))),
      DataCell(Text(apartment.apartmentName,style: TextStyle(fontSize: 4.sp))),
      DataCell(Text("${apartment.floor}",style: TextStyle(fontSize: 4.sp))),
      DataCell(Text("${apartment.area} m²",style: TextStyle(fontSize: 4.sp))),
      DataCell(Text("${apartment.description}",style: TextStyle(fontSize: 4.sp))),
      DataCell(Text(status)),
      DataCell(
        Row(children: [
          IconButton(
    icon: Icon(Icons.edit, color: Colors.blue),
    onPressed: () {
    showEditApartmentDialog(context, apartment, onRefresh);
    },
    ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              showDeleteApartmentDialog(context, apartment, onRefresh);
            },
          ),],)

      ),
    ]);
  }
  void showDeleteApartmentDialog(BuildContext context, Apartment apartment, VoidCallback onRefresh) async {
    if (apartment.isRent || apartment.isSale) {
      // Hiển thị thông báo không thể xóa
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Center(child: Text('Không thể xóa',style: TextStyle(fontSize: 5.sp),),),
          content: Text('Căn hộ này vẫn còn hợp đồng!',style: TextStyle(fontSize: 4.sp)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Hiển thị hộp thoại xác nhận xóa
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Center(child: Text('Xác nhận xóa', style: TextStyle(fontSize: 5.sp),),),
        content: Text('Bạn có chắc muốn xóa căn hộ này không?', style: TextStyle(fontSize: 4.sp)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: TextStyle(fontSize: 4.sp)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Xóa', style: TextStyle(fontSize: 4.sp)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Thực hiện xóa căn hộ
      LoadingDialog.showLoadingDialog(context, "Đang tải ...");
      await FirebaseFirestore.instance.collection('apartments').doc(apartment.id).delete();
      LoadingDialog.hideLoadingDialog(context);
      onRefresh(); // Tải lại dữ liệu
    }
  }

  void showEditApartmentDialog(BuildContext context, Apartment apartment, VoidCallback onRefresh) {
    final areaController = TextEditingController(text: apartment.area.toString());
    final rentController = TextEditingController(text: NumberFormat("#,###").format(apartment.rentPrice));
    final saleController = TextEditingController(text: NumberFormat("#,###").format(apartment.salePrice));
    final descriptionController = TextEditingController(text: apartment.description);

    bool isEditing = false;

    // StreamControllers để quản lý lỗi
    final StreamController<String?> areaErrorController = StreamController<String?>();
    final StreamController<String?> rentErrorController = StreamController<String?>();
    final StreamController<String?> saleErrorController = StreamController<String?>();
    final StreamController<String?> descriptionErrorController = StreamController<String?>();

    // Biến trạng thái lỗi
    bool areaHasError = false;
    bool rentHasError = false;
    bool saleHasError = false;
    bool descriptionHasError = false;

    // Hàm kiểm tra và phát lỗi
    void validateFields() {
      print("Validating fields...");

      if (double.tryParse(areaController.text) == null) {
        areaErrorController.add('Diện tích phải là số.');
        areaHasError = true;
        print("Error: Diện tích phải là số.");
      } else {
        areaErrorController.add(null);
        areaHasError = false;
      }

      if (int.tryParse(rentController.text.replaceAll(',', '')) == null) {
        rentErrorController.add('Giá thuê phải là số.');
        rentHasError = true;
        print("Error: Giá thuê phải là số.");
      } else {
        rentErrorController.add(null);
        rentHasError = false;
      }

      if (int.tryParse(saleController.text.replaceAll(',', '')) == null) {
        saleErrorController.add('Giá mua phải là số.');
        saleHasError = true;
        print("Error: Giá mua phải là số.");
      } else {
        saleErrorController.add(null);
        saleHasError = false;
      }

      if (descriptionController.text.isEmpty) {
        descriptionErrorController.add('Mô tả không được để trống.');
        descriptionHasError = true;
        print("Error: Mô tả không được để trống.");
      } else {
        descriptionErrorController.add(null);
        descriptionHasError = false;
      }

      print("Validation completed.");
    }

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

                    // Diện tích
                    StreamBuilder<String?>(
                      stream: areaErrorController.stream,
                      builder: (context, snapshot) {
                        return TextField(
                          controller: areaController,
                          enabled: isEditing,
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: 4.sp),
                          decoration: InputDecoration(
                            labelText: 'Diện tích (m²)',
                            labelStyle: TextStyle(fontSize: 4.sp),
                            errorText: snapshot.data,
                          ),
                          onChanged: (value) {
                            if (isEditing) validateFields();
                          },
                        );
                      },
                    ),

                    // Giá thuê
                    StreamBuilder<String?>(
                      stream: rentErrorController.stream,
                      builder: (context, snapshot) {
                        return TextField(
                          controller: rentController,
                          enabled: isEditing,
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: 4.sp),
                          decoration: InputDecoration(
                            labelText: 'Giá thuê (VNĐ)',
                            labelStyle: TextStyle(fontSize: 4.sp),
                            errorText: snapshot.data,
                          ),
                          onChanged: (value) {
                            if (isEditing) validateFields();
                          },
                        );
                      },
                    ),

                    // Giá mua
                    StreamBuilder<String?>(
                      stream: saleErrorController.stream,
                      builder: (context, snapshot) {
                        return TextField(
                          controller: saleController,
                          enabled: isEditing,
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: 4.sp),
                          decoration: InputDecoration(
                            labelText: 'Giá mua (VNĐ)',
                            labelStyle: TextStyle(fontSize: 4.sp),
                            errorText: snapshot.data,
                          ),
                          onChanged: (value) {
                            if (isEditing) validateFields();
                          },
                        );
                      },
                    ),

                    // Mô tả
                    StreamBuilder<String?>(
                      stream: descriptionErrorController.stream,
                      builder: (context, snapshot) {
                        return TextField(
                          controller: descriptionController,
                          enabled: isEditing,
                          style: TextStyle(fontSize: 4.sp),
                          decoration: InputDecoration(
                            labelText: 'Mô tả',
                            labelStyle: TextStyle(fontSize: 4.sp),
                            errorText: snapshot.data,
                          ),
                          onChanged: (value) {
                            if (isEditing) validateFields();
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (isEditing) {
                      print("Attempting to save data...");
                      validateFields();

                      // Kiểm tra nếu có lỗi
                      if (areaHasError || rentHasError || saleHasError || descriptionHasError) {
                        print("Validation failed. Cannot save.");
                        return;
                      }

                      LoadingDialog.showLoadingDialog(context, "Đang tải...");
                      try {
                        print("Saving data to Firestore...");
                        await FirebaseFirestore.instance.collection('apartments').doc(apartment.id).update({
                          'area': double.tryParse(areaController.text) ?? apartment.area,
                          'rentPrice': int.tryParse(rentController.text.replaceAll(',', '')) ?? apartment.rentPrice,
                          'salePrice': int.tryParse(saleController.text.replaceAll(',', '')) ?? apartment.salePrice,
                          'description': descriptionController.text,
                        });
                        print("Data saved successfully.");
                        LoadingDialog.hideLoadingDialog(context);
                        Navigator.pop(context);
                        onRefresh();
                      } catch (e) {
                        print("Error while saving: $e");
                        LoadingDialog.hideLoadingDialog(context);
                      }
                    } else {
                      setState(() {
                        print("Switching to edit mode...");
                        isEditing = true;
                      });
                    }
                  },
                  child: Text(isEditing ? "Lưu" : "Sửa", style: TextStyle(fontSize: 4.sp)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Đóng", style: TextStyle(fontSize: 4.sp)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => apartments.length;

  @override
  int get selectedRowCount => 0;
}
