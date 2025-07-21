import 'package:customer_app/pages/unitDetailsPage.dart';
import 'package:customer_app/sevices/database.dart';
import 'package:customer_app/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';

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
    if (!mounted) return;
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
    Set<Marker> newMarkers = {};
    for (var doc in docs) {
      print(doc.value);
      final data = Map<String, dynamic>.from(
        doc.value as Map<Object?, Object?>,
      );
      if (data.containsKey('location')) {
        final location = Map<String, dynamic>.from(
          data['location'] as Map<Object?, Object?>,
        );
        final marker = Marker(
          markerId: MarkerId(doc.key!),
          position: LatLng(
            location['latitude'].toDouble(),
            location['longitude'].toDouble(),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () {
            setState(() {
              _selectedUnitId = doc.key!;
            });
          },
          infoWindow: InfoWindow(title: doc.key!),
        );
        newMarkers.add(marker);
      }
    }
    setState(() {
      _markers = newMarkers;
    });
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
            zoomControlsEnabled: false,
            onTap: (LatLng latLng) {
              setState(() {
                _selectedUnitId = null;
              });
            },
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
                          onPressed: () async {},
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Stack(
        children: [
          // About Unit button (bottom left)
          if (_selectedUnitId != null)
            Positioned(
              left: 25,
              bottom: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyBlue,
                  foregroundColor: Colors.white,
                  minimumSize: Size(180, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              UnitDetailsPage(unitId: _selectedUnitId!),
                    ),
                  );
                },
                child: Text('About Unit'),
              ),
            ),
          // My Location FAB (bottom right)
          Positioned(
            right: 0,
            bottom: 50,
            child: FloatingActionButton(
              heroTag: 'location',
              backgroundColor: Colors.orange,
              child: Icon(Icons.my_location, color: AppColors.navyBlue),
              onPressed: _getCurrentLocation,
            ),
          ),
        ],
      ),
    );
  }
}
