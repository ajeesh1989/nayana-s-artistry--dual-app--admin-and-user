class AddressModel {
  final String id;
  final String fullName;
  final String phone;
  final String address;
  final bool isDefault;
  final String userId;
  final double? latitude; // NEW
  final double? longitude; // NEW

  AddressModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.address,
    this.isDefault = false,
    required this.userId,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phone': phone,
      'address': address,
      'isDefault': isDefault,
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory AddressModel.fromMap(String id, Map<String, dynamic> map) {
    return AddressModel(
      id: id,
      fullName: map['fullName'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      isDefault: map['isDefault'] ?? false,
      userId: map['userId'] ?? '',
      latitude: map['latitude'],
      longitude: map['longitude'],
    );
  }
}
