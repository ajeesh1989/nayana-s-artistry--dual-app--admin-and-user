import 'package:flutter/material.dart';
import 'package:nayanasartistry/user/account/address_controller.dart';
import 'package:nayanasartistry/user/account/address_model.dart';
import 'package:provider/provider.dart';

class AddAddressPage extends StatefulWidget {
  final AddressModel? existingAddress; // NEW: for edit

  const AddAddressPage({super.key, this.existingAddress});

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingAddress != null) {
      final a = widget.existingAddress!;
      _nameController.text = a.fullName;
      _phoneController.text = a.phone;
      _addressController.text = a.address;
      _isDefault = a.isDefault;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingAddress != null ? "Edit Address" : "Add Address",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _isDefault,
                onChanged: (val) {
                  setState(() {
                    _isDefault = val ?? false;
                  });
                },
                title: const Text("Set as default address"),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: Icon(Icons.save, color: colorScheme.onSecondary),
                label: Text(
                  widget.existingAddress != null
                      ? "Update Address"
                      : "Save Address",
                  style: TextStyle(color: colorScheme.onSecondary),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: colorScheme.primary,
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final addressProvider = Provider.of<AddressProvider>(
                      context,
                      listen: false,
                    );

                    if (widget.existingAddress == null) {
                      // ADD
                      final newAddress = AddressModel(
                        id: '',
                        fullName: _nameController.text.trim(),
                        phone: _phoneController.text.trim(),
                        address: _addressController.text.trim(),
                        isDefault: _isDefault,
                        userId: '',
                      );

                      await addressProvider.addAddress(newAddress);
                      await addressProvider
                          .fetchAddresses(); // This will refresh immediately
                    } else {
                      // EDIT
                      final updated = AddressModel(
                        id: widget.existingAddress!.id,
                        fullName: _nameController.text.trim(),
                        phone: _phoneController.text.trim(),
                        address: _addressController.text.trim(),
                        isDefault: _isDefault,
                        userId: '',
                      );

                      await addressProvider.editAddress(updated);
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
