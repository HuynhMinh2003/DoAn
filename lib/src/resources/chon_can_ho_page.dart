import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/apartment.dart';
import 'package:flutter/material.dart';

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
  RangeValues selectedAreaRange = const RangeValues(50, 120);

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
        apartments.add(Apartment.fromJson(doc.data()));
      }

      setState(() {
        allApartments = apartments;
        filteredApartments = apartments;
      });
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

    result = result.where((a) => a.area >= selectedAreaRange.start && a.area <= selectedAreaRange.end).toList();

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
      appBar: AppBar(title: const Text('Lọc Căn Hộ')),
      body: allApartments.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              DropdownButton<String>(
                value: selectedBuilding,
                hint: const Text('Chọn tòa'),
                items: ['Tòa A', 'Tòa B', 'Tòa C', 'Tòa D']
                    .map((building) => DropdownMenuItem(
                  value: building,
                  child: Text(building),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedBuilding = value;
                    selectedFloor = null; // Reset floor when building changes
                  });
                  applyFilters();
                },
              ),
              DropdownButton<int>(
                value: selectedFloor,
                hint: const Text('Chọn tầng'),
                items: getFloorsForSelectedBuilding()
                    .map((floor) => DropdownMenuItem(
                  value: floor,
                  child: Text('Tầng $floor'),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedFloor = value;
                  });
                  applyFilters();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Diện tích'),
          RangeSlider(
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
              applyFilters();
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: filteredApartments.length,
              itemBuilder: (context, index) {
                final apartment = filteredApartments[index];
                return ListTile(
                  title: Text('${apartment.building} - ${apartment.apartmentName}'),
                  subtitle: Text('Diện tích: ${apartment.area} m²'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
