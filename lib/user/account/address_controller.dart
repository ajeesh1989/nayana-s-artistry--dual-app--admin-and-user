import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'address_model.dart';

class AddressProvider with ChangeNotifier {
  List<AddressModel> _addresses = [];
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<AddressModel> get addresses => _addresses;

  Future<void> fetchAddresses() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('addresses')
            .get();

    _addresses =
        snapshot.docs
            .map((doc) => AddressModel.fromMap(doc.id, doc.data()))
            .toList();
    notifyListeners();
  }

  Future<void> addAddress(AddressModel address) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .add(address.toMap());

    final newAddress = AddressModel(
      id: docRef.id,
      fullName: address.fullName,
      phone: address.phone,
      address: address.address,
    );

    _addresses.add(newAddress);
    notifyListeners();
  }

  Future<void> editAddress(AddressModel updatedAddress) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .doc(updatedAddress.id)
        .update(updatedAddress.toMap());

    final index = _addresses.indexWhere((a) => a.id == updatedAddress.id);
    if (index != -1) {
      _addresses[index] = updatedAddress;
      notifyListeners();
    }
  }

  Future<void> deleteAddress(String addressId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .doc(addressId)
        .delete();

    _addresses.removeWhere((a) => a.id == addressId);
    notifyListeners();
  }

  Future<void> setDefaultAddress(String addressId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userAddressesRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('addresses');

    // Step 1: Unset previous default
    final batch = _firestore.batch();

    for (final address in _addresses) {
      final docRef = userAddressesRef.doc(address.id);
      batch.update(docRef, {'isDefault': address.id == addressId});
    }

    await batch.commit();
    await fetchAddresses(); // Refresh local list
  }
}
