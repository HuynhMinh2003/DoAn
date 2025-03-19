import 'package:do_an/src/resources/provider/resident_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'resident_details_page.dart';

class ResidentInfoPage extends StatelessWidget {
  const ResidentInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final residentProvider = Provider.of<ResidentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cư dân mới'),
      ),
      body: residentProvider.residents.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: residentProvider.residents.length,
        itemBuilder: (context, index) {
          final resident = residentProvider.residents[index];

          return ListTile(
            title: Text(resident['name'] ?? 'Không có tên'),
            subtitle: Text(resident['email'] ?? 'Không có email'),
            trailing: resident['isApproved'] == true
                ? const Icon(Icons.check_circle, color: Colors.green)
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pending, color: Colors.orange),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _deleteResident(context, resident['id'], residentProvider);
                  },
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ResidentDetailsPage(residentId: resident['id']),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _deleteResident(BuildContext context, String residentId, ResidentProvider residentProvider) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc chắn muốn xóa cư dân này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      // Xóa khỏi Firebase và danh sách cục bộ
      await residentProvider.deleteResident(residentId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa cư dân thành công!')),
      );
    }
  }
}