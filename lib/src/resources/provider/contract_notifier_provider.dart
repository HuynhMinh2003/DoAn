import 'package:flutter/foundation.dart';

class ContractNotifierProvider extends ChangeNotifier {
  bool _contractCreated = false;

  bool get contractCreated => _contractCreated;

  void markAsCreated() {
    _contractCreated = true;
    notifyListeners();
  }

  void reset() {
    _contractCreated = false;
    notifyListeners();
  }
}
