import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer_app/sevices/database.dart';
import 'package:customer_app/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';

class ViewUnitsPage extends StatefulWidget {
  @override
  _ViewUnitsPageState createState() => _ViewUnitsPageState();
}

class _ViewUnitsPageState extends State<ViewUnitsPage> {
  final TextEditingController _searchController = TextEditingController();
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  PolylinePoints polylinePoints = PolylinePoints();
  Map<PolylineId, Polyline> polylines = {};
  Position? _currentPosition;
  String? _selectedUnitId;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadUnitMarkers();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() => _currentPosition = position);
    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        12,
      ),
    );
  }

  Future<void> _loadUnitMarkers() async {
    final db = DatabaseService();
    final docs = await db.getAllUnitDocs();
    if (docs.isEmpty) {
      print('No unit documents found');
      return;
    }
    print('Retrieved unit docs:');
    for (var doc in docs) {
      print(doc.data());
      final data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('location')) {
        final GeoPoint loc = data['location'];
        final marker = Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(loc.latitude, loc.longitude),
          infoWindow: InfoWindow(title: doc.id),
        );
        setState(() {
          _markers.add(marker);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Units'),
        backgroundColor: AppColors.navyBlue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(6.9271, 79.8612), // Default Colombo coordinates
              zoom: 12,
            ),
            markers: _markers,
            polylines: Set<Polyline>.of(polylines.values),
            onMapCreated: (controller) {
              _mapController = controller;
              // Optionally reload markers if needed
              // _loadUnitMarkers();
            },
            myLocationEnabled: true,
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Column(
              children: [
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by Unit ID',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.search, color: AppColors.navyBlue),
                          onPressed: () async {
                            if (_searchController.text.isEmpty) return;
                            // Geocode area name
                            List<Location> locations;
                            try {
                              locations = await locationFromAddress(
                                _searchController.text.trim(),
                              );
                            } catch (e) {
                              locations = [];
                            }
                            if (locations.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Area not found. Please enter a valid area name.',
                                  ),
                                ),
                              );
                              return;
                            }
                            final areaLatLng = LatLng(
                              locations[0].latitude,
                              locations[0].longitude,
                            );
                            // Get all available units
                            final db = DatabaseService();
                            final docs = await db.getAllUnitDocs();
                            List<Map<String, dynamic>> availableUnits = [];
                            for (var doc in docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              if (data['status'] == 'available' &&
                                  data.containsKey('location')) {
                                final GeoPoint loc = data['location'];
                                availableUnits.add({
                                  'id': doc.id,
                                  'lat': loc.latitude,
                                  'lng': loc.longitude,
                                });
                              }
                            }
                            // Find units within 5km
                            List<Map<String, dynamic>> nearbyUnits =
                                availableUnits.where((unit) {
                                  double distance = Geolocator.distanceBetween(
                                    areaLatLng.latitude,
                                    areaLatLng.longitude,
                                    unit['lat'],
                                    unit['lng'],
                                  );
                                  return distance <= 5000;
                                }).toList();
                            if (nearbyUnits.isNotEmpty) {
                              // Move map to first nearby unit
                              _mapController.animateCamera(
                                CameraUpdate.newLatLngZoom(
                                  LatLng(
                                    nearbyUnits[0]['lat'],
                                    nearbyUnits[0]['lng'],
                                  ),
                                  14,
                                ),
                              );
                              setState(() {
                                _selectedUnitId = nearbyUnits[0]['id'];
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'No available units found in this area.',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_selectedUnitId != null)
            Positioned(
              bottom: 20,
              left: 20,
              child: SizedBox(
                width: 140, // medium size
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // square-ish
                    ),
                    alignment: Alignment.centerLeft, // left align
                    padding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  icon: Icon(
                    Icons.visibility,
                    color: Colors.white,
                  ), // proper icon
                  label: Text(
                    'View',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => {},
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(left: 25, top: 10, right: 10, bottom: 25),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10),
              FloatingActionButton(
                heroTag: 'location',
                backgroundColor: Colors.orange,
                child: Icon(Icons.my_location, color: AppColors.navyBlue),
                onPressed: _getCurrentLocation,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
