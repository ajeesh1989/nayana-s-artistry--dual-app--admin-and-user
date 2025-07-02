import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:nayanasartistry/secrets.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

class UserLocationProvider extends ChangeNotifier {
  Position? currentPosition;
  GoogleMapController? _mapController;
  Set<Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  Set<Circle> circles = {};
  double? distanceInKm;
  String? estimatedTime;
  Marker? riderMarker;
  double progressPercent = 0.0;
  List<Map<String, dynamic>> stepInstructions = [];
  int currentStepIndex = 0;
  bool _alertShown = false;

  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<Position>? _positionSubscription;

  String? get nextInstructionText =>
      currentStepIndex < stepInstructions.length
          ? stepInstructions[currentStepIndex]['instruction']
          : null;

  Future<void> initLocation({
    required double destinationLat,
    required double destinationLng,
    required BuildContext context,
  }) async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied")),
        );
      }
      return;
    }

    currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
    notifyListeners();

    await _drawPolyline(destinationLat, destinationLng);
    _calculateDistance(destinationLat, destinationLng);

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(_getRouteBounds(polylineCoordinates), 60),
    );

    _startLiveTracking(destinationLat, destinationLng, context);
  }

  void _startLiveTracking(
    double destLat,
    double destLng,
    BuildContext context,
  ) {
    _positionSubscription?.cancel();

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen((Position position) async {
      currentPosition = position;
      _calculateDistance(destLat, destLng);

      final LatLng riderLatLng = LatLng(position.latitude, position.longitude);
      _updateRiderMarker(riderLatLng);

      final double totalDistanceMeters = _calculatePolylineDistance(
        polylineCoordinates,
      );
      final LatLng closestPoint = _findClosestPointOnPolyline(
        position,
        polylineCoordinates,
      );
      final double remainingDistanceOnRoute =
          _calculatePolylineDistanceFromPoint(
            closestPoint,
            polylineCoordinates,
          );

      if (remainingDistanceOnRoute <= 20) {
        progressPercent = 1.0;
      } else if (totalDistanceMeters > 0) {
        progressPercent = (1 - (remainingDistanceOnRoute / totalDistanceMeters))
            .clamp(0.0, 1.0);
      } else {
        progressPercent = 0.0;
      }

      if (remainingDistanceOnRoute <= 50) {
        circles = {
          Circle(
            circleId: const CircleId("arrival_zone"),
            center: LatLng(destLat, destLng),
            radius: 50,
            fillColor: Colors.green.withOpacity(0.2),
            strokeColor: Colors.green,
            strokeWidth: 2,
          ),
        };
      } else {
        circles.clear();
      }

      if (remainingDistanceOnRoute <= 50) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(riderLatLng, 19.5),
        );
      } else if (remainingDistanceOnRoute <= 50) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(riderLatLng, 18.5),
        );
      } else {
        _mapController?.animateCamera(CameraUpdate.newLatLng(riderLatLng));
      }

      if (currentStepIndex < stepInstructions.length) {
        final step = stepInstructions[currentStepIndex];
        final double stepLat = step['lat'];
        final double stepLng = step['lng'];
        final double dist = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          stepLat,
          stepLng,
        );

        if (dist < 40 && step['shown'] != true) {
          step['shown'] = true;
          try {
            await _flutterTts.speak(step['instruction']);
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(step['instruction'])));
            }
          }
          currentStepIndex++;
        }
      }

      if (remainingDistanceOnRoute <= 50 && !_alertShown) {
        _alertShown = true;
        if (context.mounted) {
          Vibration.vibrate(duration: 500);
          try {
            await _audioPlayer.play(AssetSource('audio/arrival_chime.mp3'));
          } catch (e) {
            debugPrint("🔈 Failed to play chime: $e");
          }

          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: const Text("Arrived"),
                  content: const Text(
                    "You're within 50 meters of the destination.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    ),
                  ],
                ),
          );
        }
      }

      notifyListeners();
    });
  }

  void _calculateDistance(double destLat, double destLng) {
    if (currentPosition == null) return;
    final dist = Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      destLat,
      destLng,
    );
    distanceInKm = dist / 1000;
  }

  Future<void> _drawPolyline(double destLat, double destLng) async {
    if (currentPosition == null) return;

    final origin = "${currentPosition!.latitude},${currentPosition!.longitude}";
    final destination = "$destLat,$destLng";
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&mode=driving&key=$googleApiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final leg = route['legs'][0];
        final points = PolylinePoints().decodePolyline(
          route['overview_polyline']['points'],
        );

        polylineCoordinates =
            points.map((e) => LatLng(e.latitude, e.longitude)).toList();

        polylines = {
          Polyline(
            polylineId: const PolylineId("route"),
            color: Colors.blue,
            width: 5,
            points: polylineCoordinates,
          ),
        };

        distanceInKm = leg['distance']['value'] / 1000.0;
        estimatedTime = leg['duration']['text'];

        stepInstructions.clear();
        final steps = leg['steps'] as List;
        for (var step in steps) {
          final htmlInstruction = step['html_instructions'] as String;
          final plainText = _removeHtmlTags(htmlInstruction);
          final start = step['start_location'];
          final distance = step['distance']['text'];
          final duration = step['duration']['text'];

          stepInstructions.add({
            'instruction': "$plainText in $distance ($duration)",
            'lat': start['lat'],
            'lng': start['lng'],
            'shown': false,
          });
        }

        notifyListeners();
      }
    }
  }

  LatLngBounds _getRouteBounds(List<LatLng> route) {
    final swLat = route.map((p) => p.latitude).reduce(math.min);
    final swLng = route.map((p) => p.longitude).reduce(math.min);
    final neLat = route.map((p) => p.latitude).reduce(math.max);
    final neLng = route.map((p) => p.longitude).reduce(math.max);
    return LatLngBounds(
      southwest: LatLng(swLat, swLng),
      northeast: LatLng(neLat, neLng),
    );
  }

  double _calculatePolylineDistance(List<LatLng> points) {
    double totalDistance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += Geolocator.distanceBetween(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }
    return totalDistance;
  }

  LatLng _findClosestPointOnPolyline(Position current, List<LatLng> points) {
    double minDist = double.infinity;
    LatLng closestPoint = points.first;

    for (final point in points) {
      final dist = Geolocator.distanceBetween(
        current.latitude,
        current.longitude,
        point.latitude,
        point.longitude,
      );
      if (dist < minDist) {
        minDist = dist;
        closestPoint = point;
      }
    }

    return closestPoint;
  }

  double _calculatePolylineDistanceFromPoint(
    LatLng fromPoint,
    List<LatLng> points,
  ) {
    double distance = 0.0;
    bool startCounting = false;

    for (int i = 0; i < points.length - 1; i++) {
      final curr = points[i];
      final next = points[i + 1];

      if (!startCounting && curr == fromPoint) {
        startCounting = true;
      }

      if (startCounting) {
        distance += Geolocator.distanceBetween(
          curr.latitude,
          curr.longitude,
          next.latitude,
          next.longitude,
        );
      }
    }

    return distance;
  }

  void _updateRiderMarker(LatLng pos) {
    final icon = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueBlue,
    );
    riderMarker = Marker(
      markerId: const MarkerId("rider"),
      position: pos,
      icon: icon,
      rotation: _calculateBearingToNextPoint(pos),
      anchor: const Offset(0.5, 0.5),
    );
  }

  double _calculateBearingToNextPoint(LatLng current) {
    if (polylineCoordinates.isEmpty) return 0.0;
    final next = polylineCoordinates.firstWhere(
      (point) =>
          Geolocator.distanceBetween(
            current.latitude,
            current.longitude,
            point.latitude,
            point.longitude,
          ) >
          10,
      orElse: () => current,
    );

    final lat1 = current.latitude * math.pi / 180;
    final lon1 = current.longitude * math.pi / 180;
    final lat2 = next.latitude * math.pi / 180;
    final lon2 = next.longitude * math.pi / 180;
    final dLon = lon2 - lon1;

    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  String _removeHtmlTags(String htmlText) {
    final regex = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
    return htmlText.replaceAll(regex, '');
  }

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  void recenterMap() {
    if (_mapController != null && currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(currentPosition!.latitude, currentPosition!.longitude),
          17.5,
        ),
      );
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
