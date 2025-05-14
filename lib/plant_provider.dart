import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/plant_service.dart';

class PlantProvider with ChangeNotifier {
  static final PlantProvider _instance = PlantProvider._internal();
  
  factory PlantProvider() {
    return _instance;
  }
  
  PlantProvider._internal();
  
  List<dynamic>? _plants;
  bool _isLoading = false;
  String? _error;
  
  List<dynamic>? get plants => _plants;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<List<dynamic>> getPlants() async {
    // If we already have plants, return them
    if (_plants != null) {
      return _plants!;
    }
    
    // Otherwise, load plants from the API
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      Position position = await LocationService.getUserLocation();
      int hardinessZone = _determineHardinessZone(position.latitude, position.longitude);
      _plants = await PlantService.fetchPlantsByHardinessZone(hardinessZone);
      _isLoading = false;
      notifyListeners();
      return _plants!;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }
  
  int _determineHardinessZone(double lat, double lon) {
    return lat > 40 ? 5 : 7;
  }
  
  void clearCache() {
    _plants = null;
    notifyListeners();
  }
}