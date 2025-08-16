import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/user_model.dart';
import '../../models/service_request_model.dart';
import '../driver/garage_details_screen.dart';
import '../driver/service_requests_screen.dart';
import '../driver/notifications_screen.dart';
import '../driver/profile_screen.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  GoogleMapController? _mapController;
  int _currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final serviceProvider = Provider.of<ServiceProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    await locationProvider.getCurrentLocation();
    await locationProvider.getNearbyGarages();
    
    if (authProvider.currentUser != null) {
      await serviceProvider.loadDriverServiceRequests(authProvider.currentUser!.id);
      await notificationProvider.loadNotifications(authProvider.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildMapView(),
          const ServiceRequestsScreen(),
          const NotificationsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) {
                return Stack(
                  children: [
                    const Icon(Icons.notifications),
                    if (notificationProvider.unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${notificationProvider.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: 'Notifications',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Consumer2<LocationProvider, AuthProvider>(
      builder: (context, locationProvider, authProvider, child) {
        if (locationProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (locationProvider.currentPosition == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Location not available'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => locationProvider.getCurrentLocation(),
                  child: const Text('Enable Location'),
                ),
              ],
            ),
          );
        }

        final currentPos = locationProvider.currentPosition!;
        final nearbyGarages = locationProvider.nearbyGarages;

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(currentPos.latitude, currentPos.longitude),
                zoom: 14,
              ),
              onMapCreated: (controller) => _mapController = controller,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              markers: {
                // Driver marker
                Marker(
                  markerId: const MarkerId('driver'),
                  position: LatLng(currentPos.latitude, currentPos.longitude),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                  infoWindow: InfoWindow(
                    title: 'Your Location',
                    snippet: locationProvider.currentAddress ?? 'Current location',
                  ),
                ),
                // Garage markers
                ...nearbyGarages.map((garage) => Marker(
                  markerId: MarkerId(garage.id),
                  position: LatLng(garage.latitude!, garage.longitude!),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  infoWindow: InfoWindow(
                    title: garage.garageName ?? 'Garage',
                    snippet: '${locationProvider.getDistanceToGarage(garage).toStringAsFixed(1)} km away',
                  ),
                  onTap: () => _showGarageBottomSheet(garage),
                )),
              },
            ),
            
            // Top info card
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome, ${authProvider.currentUser?.fullName ?? 'Driver'}!',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${nearbyGarages.length} garages nearby',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Floating action buttons
            Positioned(
              bottom: 100,
              right: 16,
              child: Column(
                children: [
                  FloatingActionButton(
                    heroTag: 'refresh',
                    onPressed: () => locationProvider.getNearbyGarages(),
                    child: const Icon(Icons.refresh),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'location',
                    onPressed: () {
                      if (_mapController != null && locationProvider.currentPosition != null) {
                        _mapController!.animateCamera(
                          CameraUpdate.newLatLng(
                            LatLng(
                              locationProvider.currentPosition!.latitude,
                              locationProvider.currentPosition!.longitude,
                            ),
                          ),
                        );
                      }
                    },
                    child: const Icon(Icons.my_location),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showGarageBottomSheet(UserModel garage) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) {
          return Consumer<LocationProvider>(
            builder: (context, locationProvider, child) {
              final distance = locationProvider.getDistanceToGarage(garage);
              
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.build,
                            size: 30,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                garage.garageName ?? 'Garage',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                garage.ownerName ?? 'Owner',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${distance.toStringAsFixed(1)} km away',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    if (garage.address != null)
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              garage.address!,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _callGarage(garage.phone),
                            icon: const Icon(Icons.phone),
                            label: const Text('Call'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GarageDetailsScreen(garage: garage),
                                ),
                              );
                            },
                            icon: const Icon(Icons.info),
                            label: const Text('Details'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _callGarage(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not make phone call')),
        );
      }
    }
  }
}