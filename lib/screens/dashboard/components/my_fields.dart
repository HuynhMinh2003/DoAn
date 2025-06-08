import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/responsive.dart';
import 'package:do_an/src/models/my_files.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants.dart';
import 'file_info_card.dart';

class MyFiles extends StatelessWidget {
  const MyFiles({Key? key}) : super(key: key);

  Future<String?> fetchAdminFullName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await FirebaseFirestore.instance.collection('admins').doc(uid).get();
    if (doc.exists) {
      return doc['fullName'];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              "Thống kê nhân sự",
              style: TextStyle(fontSize: 4.sp),
            ),
          ],
        ),
        SizedBox(height: defaultPadding * 0.5),

        // 👇 Thêm FutureBuilder để lấy dữ liệu
        FutureBuilder<List<CloudStorageInfo>>(
          future: fetchCloudStorageInfoList(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(defaultPadding),
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Text('Lỗi: ${snapshot.error}'),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(defaultPadding),
                child: Text('Không có dữ liệu',style: TextStyle(fontSize: 5.sp,),),
              );
            }

            final data = snapshot.data!;

            return Responsive(
              mobile: FileInfoCardGridView(
                data: data,
                crossAxisCount: screenSize.width < 350 ? 1 : 2,
                childAspectRatio: screenSize.width < 350 ? 1.4 : 1.3,
              ),
              tablet: FileInfoCardGridView(data: data),
              desktop: FileInfoCardGridView(
                data: data,
                childAspectRatio: screenSize.width < 1400 ? 1.1 : 1.25,
              ),
            );
          },
        ),
      ],
    );
  }
}

class FileInfoCardGridView extends StatelessWidget {
  const FileInfoCardGridView({
    Key? key,
    required this.data,
    this.crossAxisCount = 4,
    this.childAspectRatio = 1,
  }) : super(key: key);

  final List<CloudStorageInfo> data;
  final int crossAxisCount;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: data.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: defaultPadding,
        mainAxisSpacing: defaultPadding,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) => FileInfoCard(info: data[index]),
    );
  }
}

