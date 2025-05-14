import 'package:do_an/constants.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomPaginatedTable extends StatefulWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final int rowsPerPage;
  final List<int> availableRowsPerPage;
  final ValueChanged<int>? onRowsPerPageChanged;

  const CustomPaginatedTable({
    required this.columns,
    required this.rows,
    this.rowsPerPage = 10,
    this.availableRowsPerPage = const [5, 10, 20],
    this.onRowsPerPageChanged,
    Key? key,
  }) : super(key: key);

  @override
  State<CustomPaginatedTable> createState() => _CustomPaginatedTableState();
}

class _CustomPaginatedTableState extends State<CustomPaginatedTable> {
  late int _rowsPerPage;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _rowsPerPage = widget.rowsPerPage;
    _currentPage = 1;
  }

  @override
  Widget build(BuildContext context) {
    final int startIndex = (_currentPage - 1) * _rowsPerPage;
    final int endIndex = (_currentPage * _rowsPerPage).clamp(0, widget.rows.length);

    return Column(
      children: [
        // Render Header (DataTable with rounded corners)
        ClipRRect(
          borderRadius: BorderRadius.circular(16.r), // Bo góc cho DataTable
          child: Container(
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: secondaryColor, // Màu nền của DataTable
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: DataTable(
              columns: widget.columns,
              rows: widget.rows.sublist(startIndex, endIndex),
            ),
          ),
        ),
        SizedBox(height: 8.h), // Khoảng cách giữa DataTable và Footer

        // Render Footer (Pagination Controls with rounded corners)
        ClipRRect(
          borderRadius: BorderRadius.circular(16.r), // Bo góc cho Footer
          child: Container(
            decoration: BoxDecoration(
              color: bgColor, // Màu nền footer
              borderRadius: BorderRadius.circular(16.r),
            ),
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // DropdownButton2 for rows per page
                Row(
                  children: [
                    Text("Số dòng trên mỗi trang: ", style: TextStyle(fontSize: 4.sp),),
                    DropdownButton2<int>(
                      value: _rowsPerPage,
                      items: widget.availableRowsPerPage
                          .map((rowsPerPage) => DropdownMenuItem<int>(
                        value: rowsPerPage,
                        child: Text("$rowsPerPage"),
                      ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _rowsPerPage = value;
                            _currentPage = 1;
                          });
                          if (widget.onRowsPerPageChanged != null) {
                            widget.onRowsPerPageChanged!(value);
                          }
                        }
                      },
                    ),
                  ],
                ),
                // Pagination Controls
                SizedBox(width: 20.w,),

                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.first_page),
                      onPressed: _currentPage > 1
                          ? () {
                        setState(() {
                          _currentPage = 1;
                        });
                      }
                          : null,
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_left),
                      onPressed: _currentPage > 1
                          ? () {
                        setState(() {
                          _currentPage--;
                        });
                      }
                          : null,
                    ),
                    Text("Trang $_currentPage", style: TextStyle(fontSize: 4.sp)),
                    IconButton(
                      icon: Icon(Icons.chevron_right),
                      onPressed: _currentPage * _rowsPerPage < widget.rows.length
                          ? () {
                        setState(() {
                          _currentPage++;
                        });
                      }
                          : null,
                    ),
                    IconButton(
                      icon: Icon(Icons.last_page),
                      onPressed: _currentPage * _rowsPerPage < widget.rows.length
                          ? () {
                        setState(() {
                          _currentPage =
                              (widget.rows.length / _rowsPerPage).ceil();
                        });
                      }
                          : null,
                    ),
                  ],
                ),

              ],
            ),
          ),
        ),
      ],
    );
  }
}