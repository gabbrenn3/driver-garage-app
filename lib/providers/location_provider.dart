import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class LocationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoading = false;
  String? _errorMessage;
  List<UserModel> _nearbyGarages = [];

  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<UserModel> get nearbyGarages => _nearbyGarages;

  Future<bool> requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _setError('Location services are disabled.');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _setError('Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _setError('Location permissions are permanently denied, we cannot request permissions.');
      return false;
    }

    return true;
  }

  Future<void> getCurrentLocation() async {
    try {
      _setLoading(true);
      _clearError();

      final hasPermission = await requestLocationPermission();
      if (!hasPermission) return;

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _getAddressFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      notifyListeners();
    } catch (e) {
      _setError('Failed to get current location: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _currentAddress = '${place.street}, ${place.locality}, ${place.country}';
      }
    } catch (e) {
      print('Error getting address: $e');
      _currentAddress = 'Unknown location';
    }
  }

  Future<void> getNearbyGarages({double radiusKm = 10.0}) async {
    if (_currentPosition == null) {
      await getCurrentLocation();
      if (_currentPosition == null) return;
    }

    try {
      _setLoading(true);
      
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'garage')
          .where('isActive', isEqualTo: true)
          .get();

      _nearbyGarages = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .where((garage) {
            if (garage.latitude == null || garage.longitude == null) return false;
            
            final distance = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              garage.latitude!,
              garage.longitude!,
            );
            
            return distance <= (radiusKm * 1000); // Convert km to meters
          })
          .toList();

      // Sort by distance
      _nearbyGarages.sort((a, b) {
        final distanceA = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          a.latitude!,
          a.longitude!,
        );
        final distanceB = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          b.latitude!,
          b.longitude!,
        );
        return distanceA.compareTo(distanceB);
      });

      notifyListeners();
    } catch (e) {
      _setError('Failed to get nearby garages: $e');
    } finally {
      _setLoading(false);
    }
  }

  double getDistanceToGarage(UserModel garage) {
    if (_currentPosition == null || garage.latitude == null || garage.longitude == null) {
      return 0.0;
    }

    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      garage.latitude!,
      garage.longitude!,
    ) / 1000; // Convert to kilometers
  }

  Future<double> getEstimatedTravelTime(UserModel garage) async {
    // Simple estimation: assume average speed of 30 km/h in city
    final distance = getDistanceToGarage(garage);
    return (distance / 30) * 60; // Return time in minutes
  }

  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }

  Future<void> updateUserLocation(String userId, double latitude, double longitude) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'latitude': latitude,
        'longitude': longitude,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user location: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}