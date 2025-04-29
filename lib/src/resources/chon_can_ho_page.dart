import 'dart:async'; // Thêm import Timer
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/models/apartment.dart';
import 'package:do_an/src/resources/contract_info_page.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

  List<String> getAvailableBuildings() {
    return allApartments.map((a) => a.building).toSet().toList()..sort();
  }

  RangeValues selectedAreaRange = const RangeValues(50, 120);

  Timer? _debounce;

  void showApartmentDialog(BuildContext context, Apartment apartment) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(apartment.apartmentName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Diện tích: ${apartment.area} m²'),
            Text(apartment.description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ContractInfoPage(
                  apartmentData: apartment,
                  contractType: 'rent',
                ),
              ));
            },
            child: Text("Thuê"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ContractInfoPage(
                  apartmentData: apartment,
                  contractType: 'sale',
                ),
              ));
            },
            child: Text("Mua"),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadApartmentsFromFirestore();
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

      // Sort căn hộ theo tòa nhà, tầng và tên căn hộ
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
        });
      }
    } catch (e) {
      print('Error loading apartments: $e');
    }
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
        .where((a) => a.area >= selectedAreaRange.start && a.area <= selectedAreaRange.end)
        .toList();

    setState(() {
      filteredApartments = result;
    });
  }

  List<int> getFloorsByBuilding(List<Apartment> apartments, String selectedBuilding) {
    final filtered = apartments.where((apt) => apt.building == selectedBuilding);
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
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Color(0xFFF7FEFF),
      body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                child: Image.asset('assets/images/two_circle.png', width: 160),
              ),
              SingleChildScrollView(
                child: Padding(padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 170.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Danh sách căn hộ",style: TextStyle(fontFamily: "Oswald",
                      fontWeight: FontWeight.w700,
                      fontSize: 12.sp,),),
                    SizedBox(height: 20.h),
                    SizedBox(
                      height: MediaQuery.of(context).size.height - 250,
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            children: [
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
                              SizedBox(width: 10.w), // khoảng cách giữa 2 dropdown
                              Expanded(
                                child: buildFilterDropdown<int>(
                                  label: "Chọn tầng",
                                  items: getFloorsForSelectedBuilding(),
                                  selectedValue: selectedFloor,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedFloor = value;
                                    });
                                    applyFilters();
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Padding(padding: EdgeInsets.only(left: 30.w, right: 30.w),child: Row(
                            children: [
                              Text('Diện tích', style: TextStyle(fontSize: 5.sp),),
                              Expanded(child: RangeSlider(
                                values: selectedAreaRange,
                                min: 50,
                                max: 120,
                                divisions: 7,
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
                              )
                            ],
                          )),
                          SizedBox(height: 8),
                          Expanded(
                            child: allApartments.isEmpty
                                ? ListView.builder(
                              itemCount: 6,
                              itemBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            )
                                : (filteredApartments.isEmpty
                                ? Center(
                              child: Text(
                                'Không có căn hộ nào',
                                style: TextStyle(fontSize: 16.sp, color: Colors.black54),
                              ),
                            )
                                : ListView.builder(
                              itemCount: filteredApartments.length,
                              itemBuilder: (context, index) {
                                final apartment = filteredApartments[index];
                                return ListTile(
                                  title: Text('${apartment.building} - ${apartment.apartmentName}'),
                                  subtitle: Text('Diện tích: ${apartment.area} m²'),
                                  onTap: () {
                                    showApartmentDialog(context, apartment);
                                  },
                                );
                              },
                            )),
                          ),
                        ],
                      ),
                    )
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
  }) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.height < size.width;

    return Padding(
      padding: EdgeInsets.fromLTRB(30.w, 10.h, 30.w, 8.h),
      child: SizedBox(
        height: 60.h,
        child: Container(
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<T>(
              isExpanded: true,
              hint: Text(
                label,
                style: TextStyle(color: Colors.black, fontSize: isLandscape ? 5.sp : 15.sp),
              ),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    item.toString(), // ép ra String cho cả String và int
                    style: TextStyle(fontSize: isLandscape ? 5.sp : 15.sp),
                  ),
                );
              }).toList(),
              value: selectedValue,
              onChanged: onChanged,
              buttonStyleData: ButtonStyleData(
                height: 40.h,
                padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: isLandscape ? 10.w : 25.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(color: Color(0xe2707070)),
                  color: Color(0xFFF7FEFF),
                ),
              ),
              dropdownStyleData: DropdownStyleData(
                maxHeight: 200.h,
                width: isLandscape ? 100.w : 324.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.r),
                  color: Color(0xFFF7FEFF),
                ),
                elevation: 4,
              ),
              menuItemStyleData: MenuItemStyleData(
                height: 40.h,
                padding: EdgeInsets.symmetric(horizontal: isLandscape ? 10.w : 27.w),
              ),
            ),
          ),
        ),
      ),
    );
  }

}
