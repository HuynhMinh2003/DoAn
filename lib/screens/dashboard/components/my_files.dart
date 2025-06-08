import 'package:do_an/responsive.dart';
import 'package:do_an/src/models/my_files.dart';
import 'package:flutter/material.dart';
import '../../../constants.dart';
import 'file_info_card.dart';

class MyFiles extends StatelessWidget {
  const MyFiles({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size _size = MediaQuery.of(context).size;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Thống kê thành viên",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ElevatedButton.icon(
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: defaultPadding * 1.5,
                  vertical: defaultPadding / (Responsive.isMobile(context) ? 2 : 1),
                ),
              ),
              onPressed: () {},
              icon: Icon(Icons.add),
              label: Text("Thêm mới"),
            ),
          ],
        ),
        SizedBox(height: defaultPadding),
        FutureBuilder<List<CloudStorageInfo>>(
          future: fetchCloudStorageInfoList(), // 🔁 Dữ liệu từ Firestore
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
              return const Padding(
                padding: EdgeInsets.all(defaultPadding),
                child: Text('Không có dữ liệu'),
              );
            }

            final data = snapshot.data!;
            return Responsive(
              mobile: FileInfoCardGridView(
                data: data,
                crossAxisCount: _size.width < 650 ? 2 : 4,
                childAspectRatio: _size.width < 650 ? 1.3 : 1,
              ),
              tablet: FileInfoCardGridView(data: data),
              desktop: FileInfoCardGridView(
                data: data,
                childAspectRatio: _size.width < 1400 ? 1.1 : 1.4,
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
