import 'package:flutter/material.dart';

import '../../../constants.dart';
import 'chart.dart';
import 'storage_info_card.dart';

class StorageDetails extends StatelessWidget {
  final int rentedRooms; // Số lượng phòng đã thuê
  final int soldRooms; // Số lượng phòng đã bán
  final int availableRooms; // Số lượng phòng còn trống

  const StorageDetails({
    Key? key,
    required this.rentedRooms,
    required this.soldRooms,
    required this.availableRooms,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Room Details",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: defaultPadding),
          Chart(), // Biểu đồ PieChart hiển thị trạng thái phòng
          StorageInfoCard(
            svgSrc: "assets/icons/sound_file.svg",
            title: "Rented Rooms",
            amountOfFiles: "$rentedRooms Rooms",
            numOfFiles: rentedRooms,
          ),
          StorageInfoCard(
            svgSrc: "assets/icons/sound_file.svg",
            title: "Sold Rooms",
            amountOfFiles: "$soldRooms Rooms",
            numOfFiles: soldRooms,
          ),
          StorageInfoCard(
            svgSrc: "assets/icons/sound_file.svg",
            title: "Available Rooms",
            amountOfFiles: "$availableRooms Rooms",
            numOfFiles: availableRooms,
          ),
        ],
      ),
    );
  }
}