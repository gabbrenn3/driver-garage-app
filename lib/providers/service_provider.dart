import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/service_model.dart';
import '../models/service_request_model.dart';
import '../models/user_model.dart';

class ServiceProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  
  List<ServiceModel> _services = [];
  List<ServiceRequestModel> _serviceRequests = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ServiceModel> get services => _services;
  List<ServiceRequestModel> get serviceRequests => _serviceRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Service Management
  Future<bool> addService({
    required String garageId,
    required String name,
    required String description,
    required double price,
    required int estimatedTimeMinutes,
    required String category,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final service = ServiceModel(
        id: _uuid.v4(),
        garageId: garageId,
        name: name,
        description: description,
        price: price,
        estimatedTimeMinutes: estimatedTimeMinutes,
        category: category,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('services').doc(service.id).set(service.toMap());
      _services.add(service);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add service: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateService(ServiceModel service) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedService = service.copyWith(updatedAt: DateTime.now());
      await _firestore.collection('services').doc(service.id).update(updatedService.toMap());
      
      final index = _services.indexWhere((s) => s.id == service.id);
      if (index != -1) {
        _services[index] = updatedService;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to update service: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteService(String serviceId) async {
    try {
      _setLoading(true);
      _clearError();

      await _firestore.collection('services').doc(serviceId).delete();
      _services.removeWhere((s) => s.id == serviceId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete service: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadGarageServices(String garageId) async {
    try {
      _setLoading(true);
      
      final snapshot = await _firestore
          .collection('services')
          .where('garageId', isEqualTo: garageId)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      _services = snapshot.docs
          .map((doc) => ServiceModel.fromMap(doc.data()))
          .toList();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load services: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Service Request Management
  Future<bool> createServiceRequest({
    required String driverId,
    required String garageId,
    required UserModel driver,
    required double driverLatitude,
    required double driverLongitude,
    required String driverAddress,
    List<String> servicesRequested = const [],
    String? notes,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final request = ServiceRequestModel(
        id: _uuid.v4(),
        driverId: driverId,
        garageId: garageId,
        driverName: driver.fullName,
        driverPhone: driver.phone,
        carModel: driver.carModel ?? 'Unknown',
        carPlate: driver.carPlate ?? 'Unknown',
        driverLatitude: driverLatitude,
        driverLongitude: driverLongitude,
        driverAddress: driverAddress,
        createdAt: DateTime.now(),
        servicesRequested: servicesRequested,
        notes: notes,
      );

      await _firestore.collection('service_requests').doc(request.id).set(request.toMap());
      _serviceRequests.add(request);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create service request: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateServiceRequestStatus({
    required String requestId,
    required String status,
    DateTime? acceptedAt,
    DateTime? arrivedAt,
    DateTime? completedAt,
  }) async {
    try {
      _setLoading(true);
      
      final updateData = <String, dynamic>{
        'status': status,
      };

      if (acceptedAt != null) updateData['acceptedAt'] = acceptedAt.millisecondsSinceEpoch;
      if (arrivedAt != null) updateData['arrivedAt'] = arrivedAt.millisecondsSinceEpoch;
      if (completedAt != null) updateData['completedAt'] = completedAt.millisecondsSinceEpoch;

      await _firestore.collection('service_requests').doc(requestId).update(updateData);
      
      final index = _serviceRequests.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        final request = _serviceRequests[index];
        _serviceRequests[index] = ServiceRequestModel(
          id: request.id,
          driverId: request.driverId,
          garageId: request.garageId,
          driverName: request.driverName,
          driverPhone: request.driverPhone,
          carModel: request.carModel,
          carPlate: request.carPlate,
          driverLatitude: request.driverLatitude,
          driverLongitude: request.driverLongitude,
          driverAddress: request.driverAddress,
          status: status,
          createdAt: request.createdAt,
          acceptedAt: acceptedAt ?? request.acceptedAt,
          arrivedAt: arrivedAt ?? request.arrivedAt,
          completedAt: completedAt ?? request.completedAt,
          servicesRequested: request.servicesRequested,
          servicesPerformed: request.servicesPerformed,
          totalAmount: request.totalAmount,
          isPaid: request.isPaid,
          paymentId: request.paymentId,
          notes: request.notes,
          consultationFee: request.consultationFee,
          transportFee: request.transportFee,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to update service request: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addPerformedServices({
    required String requestId,
    required List<ServicePerformed> servicesPerformed,
    double? consultationFee,
    double? transportFee,
  }) async {
    try {
      _setLoading(true);
      
      final totalServiceAmount = servicesPerformed.fold<double>(
        0.0, 
        (sum, service) => sum + service.price,
      );
      
      final totalAmount = totalServiceAmount + 
          (consultationFee ?? 0.0) + 
          (transportFee ?? 0.0);

      await _firestore.collection('service_requests').doc(requestId).update({
        'servicesPerformed': servicesPerformed.map((s) => s.toMap()).toList(),
        'totalAmount': totalAmount,
        'consultationFee': consultationFee,
        'transportFee': transportFee,
        'status': 'completed',
        'completedAt': DateTime.now().millisecondsSinceEpoch,
      });

      final index = _serviceRequests.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        final request = _serviceRequests[index];
        _serviceRequests[index] = ServiceRequestModel(
          id: request.id,
          driverId: request.driverId,
          garageId: request.garageId,
          driverName: request.driverName,
          driverPhone: request.driverPhone,
          carModel: request.carModel,
          carPlate: request.carPlate,
          driverLatitude: request.driverLatitude,
          driverLongitude: request.driverLongitude,
          driverAddress: request.driverAddress,
          status: 'completed',
          createdAt: request.createdAt,
          acceptedAt: request.acceptedAt,
          arrivedAt: request.arrivedAt,
          completedAt: DateTime.now(),
          servicesRequested: request.servicesRequested,
          servicesPerformed: servicesPerformed,
          totalAmount: totalAmount,
          isPaid: request.isPaid,
          paymentId: request.paymentId,
          notes: request.notes,
          consultationFee: consultationFee,
          transportFee: transportFee,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to add performed services: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadDriverServiceRequests(String driverId) async {
    try {
      _setLoading(true);
      
      final snapshot = await _firestore
          .collection('service_requests')
          .where('driverId', isEqualTo: driverId)
          .orderBy('createdAt', descending: true)
          .get();

      _serviceRequests = snapshot.docs
          .map((doc) => ServiceRequestModel.fromMap(doc.data()))
          .toList();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load service requests: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadGarageServiceRequests(String garageId) async {
    try {
      _setLoading(true);
      
      final snapshot = await _firestore
          .collection('service_requests')
          .where('garageId', isEqualTo: garageId)
          .orderBy('createdAt', descending: true)
          .get();

      _serviceRequests = snapshot.docs
          .map((doc) => ServiceRequestModel.fromMap(doc.data()))
          .toList();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load service requests: $e');
    } finally {
      _setLoading(false);
    }
  }

  Stream<List<ServiceRequestModel>> getServiceRequestsStream(String userId, String role) {
    final field = role == 'driver' ? 'driverId' : 'garageId';
    
    return _firestore
        .collection('service_requests')
        .where(field, isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceRequestModel.fromMap(doc.data()))
            .toList());
  }

  Future<bool> processPayment({
    required String requestId,
    required String paymentMethod,
    required double amount,
  }) async {
    try {
      _setLoading(true);
      
      // Mock payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      final paymentId = _uuid.v4();
      
      await _firestore.collection('service_requests').doc(requestId).update({
        'isPaid': true,
        'paymentId': paymentId,
        'paymentMethod': paymentMethod,
        'paidAt': DateTime.now().millisecondsSinceEpoch,
      });

      final index = _serviceRequests.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        final request = _serviceRequests[index];
        _serviceRequests[index] = ServiceRequestModel(
          id: request.id,
          driverId: request.driverId,
          garageId: request.garageId,
          driverName: request.driverName,
          driverPhone: request.driverPhone,
          carModel: request.carModel,
          carPlate: request.carPlate,
          driverLatitude: request.driverLatitude,
          driverLongitude: request.driverLongitude,
          driverAddress: request.driverAddress,
          status: request.status,
          createdAt: request.createdAt,
          acceptedAt: request.acceptedAt,
          arrivedAt: request.arrivedAt,
          completedAt: request.completedAt,
          servicesRequested: request.servicesRequested,
          servicesPerformed: request.servicesPerformed,
          totalAmount: request.totalAmount,
          isPaid: true,
          paymentId: paymentId,
          notes: request.notes,
          consultationFee: request.consultationFee,
          transportFee: request.transportFee,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Payment failed: $e');
      return false;
    } finally {
      _setLoading(false);
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