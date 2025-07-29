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
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // Map with rounded corners and shadow
          Container(
            margin: const EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    6.9271,
                    79.8612,
                  ), // Default Colombo coordinates
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
            ),
          ),
          // Modern search bar with glassmorphism effect
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: Color(0xFF9C27B0),
                      size: 24,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                        decoration: InputDecoration(
                          hintText: 'Search locker units...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6A4C93), Color(0xFF9C27B0)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Status indicator
          if (_selectedUnitId != null)
            Positioned(
              top: 110,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6A4C93), Color(0xFF9C27B0)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF6A4C93).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Unit $_selectedUnitId',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Stack(
        children: [
          // Modern booking button with glassmorphism
          if (_selectedUnitId != null)
            Positioned(
              left: 25,
              bottom: 30,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6A4C93), Color(0xFF9C27B0)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF6A4C93).withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  UnitDetailsPage(unitId: _selectedUnitId!),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.storage_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Reserve Locker',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Stylish location FAB
          Positioned(
            right: 0,
            bottom: 30,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.orange.shade400, Colors.deepOrange.shade500],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: _getCurrentLocation,
                  child: Container(
                    width: 56,
                    height: 56,
                    child: Icon(
                      Icons.my_location_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
