import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nayanasartistry/rider/user_location_controller.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class UserLocationPage extends StatelessWidget {
  final String customerName;
  final double destinationLat;
  final double destinationLng;

  const UserLocationPage({
    super.key,
    required this.customerName,
    required this.destinationLat,
    required this.destinationLng,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) =>
              UserLocationProvider()..initLocation(
                destinationLat: destinationLat,
                destinationLng: destinationLng,
                context: context,
              ),
      child: Consumer<UserLocationProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            body:
                provider.currentPosition == null
                    ? const Center(child: CircularProgressIndicator())
                    : Stack(
                      children: [
                        GoogleMap(
                          onMapCreated: provider.setMapController,
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              provider.currentPosition!.latitude,
                              provider.currentPosition!.longitude,
                            ),
                            zoom: 17.5,
                          ),
                          polylines: provider.polylines,
                          markers: {
                            if (provider.riderMarker != null)
                              provider.riderMarker!,
                            Marker(
                              markerId: const MarkerId("customer"),
                              position: LatLng(destinationLat, destinationLng),
                              infoWindow: const InfoWindow(title: "🏠 Home"),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueRed,
                              ),
                            ),
                          },
                          circles: provider.circles,
                          myLocationEnabled: false,
                          zoomControlsEnabled: true,
                          zoomGesturesEnabled: true,
                          myLocationButtonEnabled: false,
                        ),

                        // 📍 Navigation Banner + Progress Bar
                        // Positioned(
                        //   top: 40,
                        //   left: 16,
                        //   right: 16,
                        //   child: Column(
                        //     crossAxisAlignment: CrossAxisAlignment.stretch,
                        //     children: [
                        //       Material(
                        //         elevation: 6,
                        //         borderRadius: BorderRadius.circular(12),
                        //         color: Colors.black87,
                        //         child: Padding(
                        //           padding: const EdgeInsets.all(12),
                        //           child: Row(
                        //             children: [
                        //               const Icon(
                        //                 Icons.navigation,
                        //                 color: Colors.white,
                        //               ),
                        //               const SizedBox(width: 10),
                        //               Expanded(
                        //                 child: Text(
                        //                   provider.nextInstructionText ??
                        //                       'Waiting for directions...',
                        //                   style: const TextStyle(
                        //                     color: Colors.white,
                        //                     fontSize: 14,
                        //                   ),
                        //                 ),
                        //               ),
                        //             ],
                        //           ),
                        //         ),
                        //       ),
                        //       const SizedBox(height: 10),
                        //       ClipRRect(
                        //         borderRadius: BorderRadius.circular(8),
                        //         child: LinearProgressIndicator(
                        //           value: provider.progressPercent.clamp(
                        //             0.0,
                        //             1.0,
                        //           ),
                        //           backgroundColor: Colors.grey[300],
                        //           valueColor:
                        //               const AlwaysStoppedAnimation<Color>(
                        //                 Colors.green,
                        //               ),
                        //           minHeight: 6,
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),

                        // ✅ Bottom Card
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Card(
                            margin: EdgeInsets.zero,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            elevation: 14,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 22,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.person_pin_circle,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "Delivering to $customerName",
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // 🧭 Instruction and Progress Bar
                                  const SizedBox(height: 12),
                                  Material(
                                    elevation: 2,
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.black87,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.navigation,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              provider.nextInstructionText ??
                                                  'Waiting for directions...',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: provider.progressPercent.clamp(
                                        0.0,
                                        1.0,
                                      ),
                                      backgroundColor: Colors.grey[300],
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Colors.green,
                                          ),
                                      minHeight: 6,
                                    ),
                                  ),

                                  if (provider.distanceInKm != null) ...[
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.directions,
                                          size: 20,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Distance: ${provider.distanceInKm!.toStringAsFixed(2)} km",
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.timer,
                                          size: 20,
                                          color: Colors.orange,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "ETA: ${provider.estimatedTime ?? 'Calculating...'}",
                                        ),
                                      ],
                                    ),
                                  ],

                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: provider.recenterMap,
                                          icon: const Icon(Icons.my_location),
                                          label: const Text("Recenter"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            final lat =
                                                provider
                                                    .currentPosition
                                                    ?.latitude ??
                                                0;
                                            final lng =
                                                provider
                                                    .currentPosition
                                                    ?.longitude ??
                                                0;
                                            final gMapUrl =
                                                'https://www.google.com/maps/dir/?api=1&origin=$lat,$lng&destination=$destinationLat,$destinationLng&travelmode=driving';

                                            showDialog(
                                              context: context,
                                              builder:
                                                  (_) => AlertDialog(
                                                    title: const Text(
                                                      "Open in Maps",
                                                    ),
                                                    content: const Text(
                                                      "Do you want to open this route in Google Maps?",
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                            ),
                                                        child: const Text(
                                                          "Cancel",
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () async {
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                          await launchUrl(
                                                            Uri.parse(gMapUrl),
                                                          );
                                                        },
                                                        child: const Text(
                                                          "Open",
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                            );
                                          },
                                          icon: const Icon(Icons.map),
                                          label: const Text("Google Maps"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blueGrey,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
          );
        },
      ),
    );
  }
}
