import 'package:do_an/screens/dashboard/components/chart.dart';
import 'package:do_an/screens/dashboard/components/storage_info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants.dart';

class StorageDetails extends StatelessWidget {
  final int totalApartments;
  final int apartmentsWithContract;
  final int apartmentsWithoutContract;
  final int activeContracts;
  final int expiredContracts;

  const StorageDetails({
    Key? key,
    required this.totalApartments,
    required this.apartmentsWithContract,
    required this.apartmentsWithoutContract,
    this.activeContracts = 0,
    this.expiredContracts = 0,
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
            "Thống kê hợp đồng dịch vụ",
            style: TextStyle(
              fontSize: 4.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: defaultPadding),
          Chart(),
          StorageInfoCard(
            svgSrc: "assets/icons/contract_co.svg",
            title: "Căn đã có",
            amountOfFiles: "$apartmentsWithContract căn",
          ),
          StorageInfoCard(
            svgSrc: "assets/icons/contract_ko.svg",
            title: "Căn chưa có",
            amountOfFiles: "$apartmentsWithoutContract căn",
          ),
          StorageInfoCard(
            svgSrc: "assets/icons/contract_con.svg",
            title: "Còn hiệu lực",
            amountOfFiles: "$activeContracts hợp đồng",
          ),
          StorageInfoCard(
            svgSrc: "assets/icons/contract_het.svg",
            title: "Hết hạn",
            amountOfFiles: "$expiredContracts hợp đồng",
          ),
        ],
      ),
    );
  }
}
