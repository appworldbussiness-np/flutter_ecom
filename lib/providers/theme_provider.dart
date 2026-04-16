import 'package:flutter/material.dart';
import 'package:ecom_/core_services/localstorage_services.dart';

class StorageProvider extends ChangeNotifier {
  final storageService = LocalStorageService();

  bool _isdarkthme = false;

  bool get isDarktheme => _isdarkthme;
  StorageProvider() {
    _init();
  }

  Future<void> _init() async {
    await getdarktheme();
    notifyListeners();
  }

  Future<void> setdarktheme(bool value) async {
    _isdarkthme = value;
    await storageService.setdarktheme(value); // ✅ persist to local storage
    notifyListeners();
  }

  Future<void> getdarktheme() async {
    _isdarkthme = await storageService.getdarktheme();
    notifyListeners();
  }
}
