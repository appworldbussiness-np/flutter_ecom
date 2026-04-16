class AddressStore {
  static String? name;
  static String? phone;
  static String? address;
  static String? city;

  static void save({
    required String name,
    required String phone,
    required String address,
    required String city,
  }) {
    AddressStore.name = name;
    AddressStore.phone = phone;
    AddressStore.address = address;
    AddressStore.city = city;
  }

  static bool get hasData =>
      name != null && phone != null && address != null && city != null;

  static void clear() {
    name = null;
    phone = null;
    address = null;
    city = null;
  }
}
