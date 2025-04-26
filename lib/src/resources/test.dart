import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
      Stack(
        children: [
          const Text("data"),
          Container(
            width: double.infinity,
            child: DraggableScrollableSheet(
              initialChildSize: 0.09,  // Chiếm % màn hình lúc đầu
              minChildSize: 0.09,      // Không thu nhỏ hơn mức này
              maxChildSize: 0.5,     // Kéo lên được gần full màn hình
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30.r),
                      topRight: Radius.circular(30.r),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Thanh kéo
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          margin: EdgeInsets.only(top: 8, bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      // Header cố định
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: Center(child: Text(
                              "Danh sách công việc của bạn",
                              style: TextStyle(fontFamily: "Oswald",fontSize: 18.sp, fontWeight: FontWeight.bold),
                            ),)
                        ),
                      ),

                      SizedBox(height: 20),

                      // Danh sách scroll bên dưới
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: 20,
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text("Công việc ${index + 1}"),
                              subtitle: Text("Chi tiết công việc ở đây"),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          )

        ],

      )
    );
  }
}
