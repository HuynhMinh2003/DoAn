import 'package:do_an/src/resources/ds_canho_page.dart';
import 'package:do_an/src/resources/ds_hopdong_canho_page.dart';
import 'package:do_an/src/resources/ds_nhanvien_page.dart';
import 'package:do_an/src/resources/quan_li_web.dart';
import 'package:do_an/src/resources/tao_tk_nv.dart';
import 'package:do_an/src/resources/resident_page.dart';
import 'package:do_an/src/resources/tao_tk_ctdv_ngoai.dart';
import 'package:do_an/src/resources/update_fee_page.dart';
import 'package:go_router/go_router.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const AdminWebPage()),
    GoRoute(path: '/hop-dong', builder: (_, __) => const ContractListPage()),
    GoRoute(path: '/danh-sach-phong', builder: (_, __) => const ApartmentListPage()),
    GoRoute(path: '/tao-nhan-vien', builder: (_, __) => const AddAccountStaffPage()),
    GoRoute(path: '/ds-nhan-vien', builder: (_, __) => const StaffListPage()),
    GoRoute(path: '/cu-dan', builder: (_, __) => ResidentPage()),
    GoRoute(path: '/cty-dich-vu', builder: (_, __) => const AddAccountCompanyPage()),
    GoRoute(path: '/gia-dich-vu', builder: (_, __) => UpdateFeeScreen()),
  ],
);
