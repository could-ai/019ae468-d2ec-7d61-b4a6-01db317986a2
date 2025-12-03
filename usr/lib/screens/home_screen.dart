import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:couldai_user_app/screens/help_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Default to a central location (e.g., London) if GPS not available
  LatLng _currentCenter = const LatLng(51.509364, -0.128928);
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();
  
  bool _isMocking = false;
  bool _useJitter = true; // "Humanize" the location
  Timer? _mockTimer;
  
  // Simulation stats
  int _updatesSent = 0;
  String _statusMessage = "Ready to spoof";

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mockTimer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentCenter = LatLng(position.latitude, position.longitude);
      // Don't auto-select, let user choose
      _mapController.move(_currentCenter, 15);
    });
  }

  void _handleTap(TapPosition tapPosition, LatLng point) {
    if (_isMocking) return; // Don't change location while active
    setState(() {
      _selectedLocation = point;
    });
  }

  void _toggleMocking() {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a location on the map first.")),
      );
      return;
    }

    setState(() {
      _isMocking = !_isMocking;
    });

    if (_isMocking) {
      _startMockSimulation();
    } else {
      _stopMockSimulation();
    }
  }

  void _startMockSimulation() {
    setState(() {
      _statusMessage = "Broadcasting fake signal...";
      _updatesSent = 0;
    });

    // In a real scenario, this would use platform channels to set the mock location
    // provided the user has enabled this app as the "Mock Location App" in developer settings.
    // Here we simulate the "Humanized" jitter logic.
    
    _mockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _updatesSent++;
        
        if (_useJitter && _selectedLocation != null) {
          // Add tiny random variations to simulate GPS noise/drift
          // 0.00001 degrees is roughly 1.1 meters
          final random = Random();
          double latOffset = (random.nextDouble() - 0.5) * 0.00005; 
          double lngOffset = (random.nextDouble() - 0.5) * 0.00005;
          
          // We don't actually move the pin visually to keep UI clean, 
          // but we update the status to show "live" data
          _statusMessage = "Broadcasting: ${_selectedLocation!.latitude + latOffset}\n${_selectedLocation!.longitude + lngOffset}";
        }
      });
    });
  }

  void _stopMockSimulation() {
    _mockTimer?.cancel();
    setState(() {
      _statusMessage = "Simulation stopped";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.radar, color: Colors.greenAccent),
            SizedBox(width: 10),
            Text("Stealth GPS"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpScreen()),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Status Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: _isMocking ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isMocking ? "STATUS: ACTIVE" : "STATUS: IDLE",
                      style: TextStyle(
                        color: _isMocking ? Colors.greenAccent : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isMocking)
                      Text(
                        "Updates sent: $_updatesSent",
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                  ],
                ),
                Switch(
                  value: _useJitter,
                  onChanged: _isMocking ? null : (val) {
                    setState(() {
                      _useJitter = val;
                    });
                  },
                  activeColor: Colors.greenAccent,
                ),
              ],
            ),
          ),
          if (_isMocking)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: Colors.black54,
              child: Text(
                "Mode: ${_useJitter ? 'Humanized (Anti-Detection)' : 'Static'}",
                style: const TextStyle(fontSize: 10, color: Colors.greenAccent),
              ),
            ),
            
          // Map
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentCenter,
                    initialZoom: 13.0,
                    onTap: _handleTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.couldai_user_app',
                      // Dark mode filter for map tiles
                      tileBuilder: (context, widget, tile) {
                        return ColorFiltered(
                          colorFilter: const ColorFilter.matrix(<double>[
                            -1,  0,  0, 0, 255,
                             0, -1,  0, 0, 255,
                             0,  0, -1, 0, 255,
                             0,  0,  0, 1,   0,
                          ]),
                          child: widget,
                        );
                      },
                    ),
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation!,
                            width: 80,
                            height: 80,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.greenAccent,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                
                // Overlay controls
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        heroTag: "gps",
                        mini: true,
                        backgroundColor: Colors.black87,
                        child: const Icon(Icons.my_location, color: Colors.white),
                        onPressed: () {
                          _mapController.move(_currentCenter, 15);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Control Panel
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedLocation != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      "Target: ${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)}",
                      style: const TextStyle(fontFamily: 'Monospace', color: Colors.white70),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _selectedLocation == null ? null : _toggleMocking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isMocking ? Colors.redAccent : Colors.greenAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _isMocking ? "STOP SIMULATION" : "START SPOOFING",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
