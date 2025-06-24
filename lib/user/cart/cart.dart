import 'package:flutter/material.dart';
import 'package:nayanasartistry/user/account/address_controller.dart';
import 'package:nayanasartistry/user/account/select_address.dart';
import 'package:nayanasartistry/user/buy_now/buy_now.dart';
import 'package:nayanasartistry/user/cart/cart_controller.dart';
import 'package:nayanasartistry/user/account/address_model.dart';
import 'package:provider/provider.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  static const double deliveryCharge = 100.0;

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final addressProvider = Provider.of<AddressProvider>(context);
    final cartItems = cartProvider.cartItems;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final addresses = addressProvider.addresses;
    final selectedAddress = addresses.firstWhere(
      (a) => a.isDefault,
      orElse:
          () =>
              addresses.isNotEmpty
                  ? addresses.first
                  : AddressModel(
                    id: '',
                    fullName: '',
                    phone: '',
                    address: '',
                    userId: '',
                  ),
    );

    final subtotal = cartItems.fold<double>(
      0,
      (sum, item) => sum + (item['price'] as num).toDouble(),
    );
    final grandTotal = subtotal + deliveryCharge;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        centerTitle: true,
        elevation: 0.5,
      ),
      body:
          cartItems.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text('Your cart is empty', style: textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Add items to your cart and shop easily.',
                      style: textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selectedAddress.address.isNotEmpty) ...[
                      Text("Deliver to:", style: textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${selectedAddress.fullName} • ${selectedAddress.phone}",
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  selectedAddress.address,
                                  style: textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SelectAddressPage(),
                                ),
                              );
                            },
                            child: const Text("Change"),
                          ),
                        ],
                      ),
                      const Divider(thickness: 1),
                    ],
                    ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: cartItems.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child:
                                item['imageUrls'] != null &&
                                        item['imageUrls'].isNotEmpty
                                    ? Image.network(
                                      item['imageUrls'][0],
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    )
                                    : Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image),
                                    ),
                          ),
                          title: Text(item['name'] ?? ''),
                          subtitle: Text("₹${item['price']}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () {
                              cartProvider.removeFromCart(item['id']);
                            },
                          ),
                        );
                      },
                    ),
                    const Divider(thickness: 1, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal'),
                        Text("₹${subtotal.toStringAsFixed(2)}"),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery Charge'),
                        Text("₹${deliveryCharge.toStringAsFixed(2)}"),
                      ],
                    ),
                    const Divider(thickness: 1, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Grand Total',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "₹${grandTotal.toStringAsFixed(2)}",
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: colorScheme.primary,
                        ),
                        onPressed:
                            addresses.isEmpty
                                ? null
                                : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => BuyNowPage(
                                            amount: grandTotal,
                                            customerName:
                                                selectedAddress.fullName,
                                            customerPhone:
                                                selectedAddress.phone,
                                            customerEmail:
                                                'test@example.com', // Replace with actual user email if available
                                            address: selectedAddress,
                                            productData: {
                                              'items': cartItems,
                                              'price': grandTotal,
                                            },
                                          ),
                                    ),
                                  );
                                },
                        child: Text(
                          "Place Order",
                          style: TextStyle(color: colorScheme.onSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
