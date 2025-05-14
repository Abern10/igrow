import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_plants.dart';
import '../models/user_model.dart';
import 'dart:developer' as developer;

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  
  // Get user plants collection reference for a specific user
  CollectionReference _getUserPlantsCollection(String userId) {
    return _usersCollection.doc(userId).collection('plants');
  }
  
  // Create or update user in Firestore
  Future<void> saveUserData(AppUser user) async {
    try {
      developer.log('Attempting to save user data for uid: ${user.uid}', name: 'FirebaseService');
      
      // Check if the document already exists
      DocumentSnapshot userDoc = await _usersCollection.doc(user.uid).get();
      
      if (userDoc.exists) {
        developer.log('User document exists, updating with merge', name: 'FirebaseService');
      } else {
        developer.log('User document does not exist, creating new document', name: 'FirebaseService');
      }
      
      // Convert user to map for storage
      Map<String, dynamic> userData = user.toMap();
      developer.log('User data prepared for Firestore: $userData', name: 'FirebaseService');
      
      await _usersCollection.doc(user.uid).set(userData, SetOptions(merge: true));
      developer.log('User data saved successfully for uid: ${user.uid}', name: 'FirebaseService');
    } catch (e, stackTrace) {
      developer.log(
        'Error saving user data for uid: ${user.uid}',
        name: 'FirebaseService',
        error: e,
        stackTrace: stackTrace
      );
      rethrow;
    }
  }

  // Update user data with firstName and lastName (no displayName)
  Future<void> updateUserNameFields(String userId, String firstName, String lastName) async {
    try {
      developer.log('Updating name fields for user: $userId', name: 'FirebaseService');
      
      await _usersCollection.doc(userId).update({
        'firstName': firstName,
        'lastName': lastName,
      });
      
      developer.log('Successfully updated name fields: firstName=$firstName, lastName=$lastName', 
                  name: 'FirebaseService');
                  
    } catch (e, stackTrace) {
      developer.log(
        'Error updating user name fields',
        name: 'FirebaseService',
        error: e,
        stackTrace: stackTrace
      );
      rethrow;
    }
  }
  
  // Get user data from Firestore
  Future<AppUser?> getUserData(String userId) async {
    try {
      developer.log('Fetching user data for uid: $userId', name: 'FirebaseService');
      
      DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();
      
      if (userDoc.exists) {
        developer.log('User document found for uid: $userId', name: 'FirebaseService');
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return AppUser.fromMap(userData);
      } else {
        developer.log('No user document found for uid: $userId', name: 'FirebaseService');
        return null;
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error fetching user data for uid: $userId',
        name: 'FirebaseService',
        error: e,
        stackTrace: stackTrace
      );
      rethrow;
    }
  }
  
  // Get user data as stream
  Stream<AppUser?> getUserStream(String userId) {
    developer.log('Setting up user data stream for uid: $userId', name: 'FirebaseService');
    
    return _usersCollection.doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        try {
          Map<String, dynamic> userData = snapshot.data() as Map<String, dynamic>;
          return AppUser.fromMap(userData);
        } catch (e, stackTrace) {
          developer.log(
            'Error parsing user data from stream for uid: $userId',
            name: 'FirebaseService',
            error: e,
            stackTrace: stackTrace
          );
          return null;
        }
      } else {
        return null;
      }
    });
  }
  
  // Update user's coin balance
  Future<void> updateUserCoins(String userId, int newCoins) async {
    try {
      developer.log('Updating coins for user $userId to $newCoins', name: 'FirebaseService');
      
      await _usersCollection.doc(userId).update({'coins': newCoins});
      developer.log('Coins updated successfully for user $userId', name: 'FirebaseService');
    } catch (e, stackTrace) {
      developer.log(
        'Error updating coins for user $userId',
        name: 'FirebaseService',
        error: e,
        stackTrace: stackTrace
      );
      rethrow;
    }
  }
  
  // Update user's last login timestamp
  Future<void> updateLastLogin(String userId) async {
    try {
      developer.log('Updating last login timestamp for user $userId', name: 'FirebaseService');
      
      await _usersCollection.doc(userId).update({
        'lastLogin': DateTime.now().millisecondsSinceEpoch
      });
      
      developer.log('Last login timestamp updated successfully for user $userId', name: 'FirebaseService');
    } catch (e, stackTrace) {
      developer.log(
        'Error updating last login timestamp for user $userId',
        name: 'FirebaseService',
        error: e,
        stackTrace: stackTrace
      );
      rethrow;
    }
  }
  
  // Save a plant to user's collection
  Future<void> savePlant(String userId, Plant plant) async {
    try {
      developer.log('Saving plant ${plant.id} for user $userId', name: 'FirebaseService');
      
      // Convert plant to map for storage
      Map<String, dynamic> plantData = plant.toMap();
      developer.log('Plant data prepared for Firestore: $plantData', name: 'FirebaseService');
      
      await _getUserPlantsCollection(userId).doc(plant.id).set(plantData);
      developer.log('Plant saved successfully for user $userId', name: 'FirebaseService');
    } catch (e, stackTrace) {
      developer.log(
        'Error saving plant ${plant.id} for user $userId',
        name: 'FirebaseService',
        error: e,
        stackTrace: stackTrace
      );
      rethrow;
    }
  }
  
  // Get stream of user's plants
  Stream<List<Plant>> getUserPlants(String userId) {
    developer.log('Setting up plants stream for user $userId', name: 'FirebaseService');
    
    return _getUserPlantsCollection(userId)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) {
              try {
                return Plant.fromMap(doc.data() as Map<String, dynamic>);
              } catch (e, stackTrace) {
                developer.log(
                  'Error parsing plant data from stream for user $userId',
                  name: 'FirebaseService',
                  error: e,
                  stackTrace: stackTrace
                );
                // Return a default plant on error to prevent stream failure
                return Plant(
                  id: doc.id,
                  name: 'Error Loading Plant',
                );
              }
            }).toList());
  }
  
  // Delete a plant from user's collection
  Future<void> deletePlant(String userId, String plantId) async {
    try {
      developer.log('Deleting plant $plantId for user $userId', name: 'FirebaseService');
      
      await _getUserPlantsCollection(userId).doc(plantId).delete();
      developer.log('Plant deleted successfully for user $userId', name: 'FirebaseService');
    } catch (e, stackTrace) {
      developer.log(
        'Error deleting plant $plantId for user $userId',
        name: 'FirebaseService',
        error: e,
        stackTrace: stackTrace
      );
      rethrow;
    }
  }
  
  // Update plant's health status
  Future<void> updatePlantHealth(String userId, String plantId, int newHealth) async {
    try {
      developer.log('Updating health for plant $plantId (user $userId) to $newHealth', name: 'FirebaseService');
      
      await _getUserPlantsCollection(userId).doc(plantId).update({
        'healthStatus': newHealth
      });
      
      developer.log('Health updated successfully for plant $plantId', name: 'FirebaseService');
    } catch (e, stackTrace) {
      developer.log(
        'Error updating health for plant $plantId (user $userId)',
        name: 'FirebaseService',
        error: e,
        stackTrace: stackTrace
      );
      rethrow;
    }
  }
  
  // Update plant's water level
  Future<void> updatePlantWaterLevel(String userId, String plantId, int newWaterLevel) async {
    try {
      developer.log('Updating water level for plant $plantId (user $userId) to $newWaterLevel', name: 'FirebaseService');
      
      await _getUserPlantsCollection(userId).doc(plantId).update({
        'waterLevel': newWaterLevel
      });
      
      developer.log('Water level updated successfully for plant $plantId', name: 'FirebaseService');
    } catch (e, stackTrace) {
      developer.log(
        'Error updating water level for plant $plantId (user $userId)',
        name: 'FirebaseService',
        error: e,
        stackTrace: stackTrace
      );
      rethrow;
    }
  }
  
  // Update plant's fertilize level
  Future<void> updatePlantFertilizeLevel(String userId, String plantId, int newFertilizeLevel) async {
    try {
      developer.log('Updating fertilize level for plant $plantId (user $userId) to $newFertilizeLevel', name: 'FirebaseService');
      
      await _getUserPlantsCollection(userId).doc(plantId).update({
        'fertilizeLevel': newFertilizeLevel
      });
      
      developer.log('Fertilize level updated successfully for plant $plantId', name: 'FirebaseService');
    } catch (e, stackTrace) {
      developer.log(
        'Error updating fertilize level for plant $plantId (user $userId)',
        name: 'FirebaseService',
        error: e,
        stackTrace: stackTrace
      );
      rethrow;
    }
  }
  
  // Update plant's growth stage
  Future<void> updatePlantGrowthStage(String userId, String plantId, String newGrowthStage) async {
    try {
      developer.log('Updating growth stage for plant $plantId (user $userId) to $newGrowthStage', name: 'FirebaseService');
      
      await _getUserPlantsCollection(userId).doc(plantId).update({
        'growthStage': newGrowthStage
      });
      
      developer.log('Growth stage updated successfully for plant $plantId', name: 'FirebaseService');
    } catch (e, stackTrace) {
      developer.log(
        'Error updating growth stage for plant $plantId (user $userId)',
        name: 'FirebaseService',
        error: e,
        stackTrace: stackTrace
      );
      rethrow;
    }
  }
}
