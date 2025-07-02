import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nayanasartistry/user/account/address_controller.dart';
import 'package:nayanasartistry/user/account/address_model.dart';
import 'package:provider/provider.dart';

class AddAddressPage extends StatefulWidget {
  final AddressModel? existingAddress;

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

  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    if (widget.existingAddress != null) {
      final a = widget.existingAddress!;
      _nameController.text = a.fullName;
      _phoneController.text = a.phone;
      _addressController.text = a.address;
      _isDefault = a.isDefault;
      _latitude = a.latitude;
      _longitude = a.longitude;
    }
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission denied")),
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Location set: ($_latitude, $_longitude)")),
    );
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
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: const Text("Use My Location"),
              ),
              if (_latitude != null && _longitude != null)
                Text(
                  "📍 Location: $_latitude, $_longitude",
                  style: TextStyle(color: Colors.grey[700]),
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

                    final newAddress = AddressModel(
                      id: widget.existingAddress?.id ?? '',
                      fullName: _nameController.text.trim(),
                      phone: _phoneController.text.trim(),
                      address: _addressController.text.trim(),
                      isDefault: _isDefault,
                      userId: '',
                      latitude: _latitude,
                      longitude: _longitude,
                    );

                    if (widget.existingAddress == null) {
                      await addressProvider.addAddress(newAddress);
                      await addressProvider.fetchAddresses();
                    } else {
                      await addressProvider.editAddress(newAddress);
                    }

                    if (context.mounted) Navigator.pop(context);
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
