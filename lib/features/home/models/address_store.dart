import 'package:shared_preferences/shared_preferences.dart';

class AddressStore {
  static String? name;
  static String? phone;
  static String? address;
  static String? city;

  /// ✅ CHECK DATA
  static bool get hasData =>
      name != null && phone != null && address != null && city != null;

  /// ✅ SAVE (PERSISTENT)
  static Future<void> save({
    required String name,
    required String phone,
    required String address,
    required String city,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('name', name);
    await prefs.setString('phone', phone);
    await prefs.setString('address', address);
    await prefs.setString('city', city);

    /// also keep in memory
    AddressStore.name = name;
    AddressStore.phone = phone;
    AddressStore.address = address;
    AddressStore.city = city;
  }

  /// ✅ LOAD (FROM STORAGE)
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    name = prefs.getString('name');
    phone = prefs.getString('phone');
    address = prefs.getString('address');
    city = prefs.getString('city');
  }

  /// ✅ CLEAR (OPTIONAL)
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('name');
    await prefs.remove('phone');
    await prefs.remove('address');
    await prefs.remove('city');

    name = null;
    phone = null;
    address = null;
    city = null;
  }
}
