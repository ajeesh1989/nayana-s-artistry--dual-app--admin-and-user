import 'package:flutter/material.dart';
import 'package:nayanasartistry/user/account/add_address.dart';
import 'package:provider/provider.dart';
import 'package:nayanasartistry/user/account/address_controller.dart';
import 'package:nayanasartistry/user/account/address_model.dart';

class SelectAddressPage extends StatelessWidget {
  const SelectAddressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final addressProvider = Provider.of<AddressProvider>(context);
    final addresses = addressProvider.addresses;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Select Address")),
      body:
          addresses.isEmpty
              ? const Center(child: Text("No saved addresses"))
              : ListView.builder(
                itemCount: addresses.length,
                itemBuilder: (context, index) {
                  final address = addresses[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: Icon(
                        address.isDefault
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: address.isDefault ? colorScheme.primary : null,
                      ),
                      title: Text(
                        "${address.fullName} • ${address.phone}",
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(address.address),

                      onTap: () async {
                        await addressProvider.setDefaultAddress(address.id);
                        Navigator.pop(context); // Return to Cart Page
                      },
                    ),
                  );
                },
              ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.add_location_alt),
          label: const Text("Add New Address"),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddAddressPage()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}
