class AddressModel {
  final String id;
  final String fullName;
  final String phone;
  final String address;
  final bool isDefault;
  final String userId; // 👈 Added userId field

  AddressModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.address,
    this.isDefault = false,
    required this.userId, // 👈 Added in constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phone': phone,
      'address': address,
      'isDefault': isDefault,
      'userId': userId, // 👈 Added to map
    };
  }

  factory AddressModel.fromMap(String id, Map<String, dynamic> map) {
    return AddressModel(
      id: id,
      fullName: map['fullName'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      isDefault: map['isDefault'] ?? false,
      userId: map['userId'] ?? '', // 👈 Parse userId
    );
  }
}
