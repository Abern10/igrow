import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../models/user_plants.dart';
import 'plant_provider.dart';

class FlowersPage extends StatefulWidget {
  final int initialTabIndex;
  
  const FlowersPage({super.key, this.initialTabIndex = 0});

  @override
  FlowersPageState createState() => FlowersPageState();
}

class FlowersPageState extends State<FlowersPage> with SingleTickerProviderStateMixin {
  late Future<List<dynamic>> _plantsFuture;
  final FirebaseService firebaseService = FirebaseService();
  final AuthService authService = AuthService();
  late TabController _tabController;
  final PlantProvider plantProvider = PlantProvider();
  late Stream<List<Plant>> _userPlantsStream;

  @override
  void initState() {
    super.initState();
    _plantsFuture = plantProvider.getPlants();
    _tabController = TabController(
      length: 2, 
      vsync: this,
      initialIndex: widget.initialTabIndex, // Use the initialTabIndex
    );
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = authService.userId ?? 'test_user';
    _userPlantsStream = firebaseService.getUserPlants(userId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _savePlant(Map<String, dynamic> plantData) async {
    try {
      final userId = authService.userId ?? 'test_user';
      
      await firebaseService.savePlant(
        userId,
        Plant(
          id: DateTime.now().toString(), // Consider using UUID instead
          name: plantData['common_name'] ?? 'Unknown Plant',
          imageUrl: plantData['default_image']?['thumbnail'],
          careInstructions: plantData['scientific_name']?.join(', '),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Plant added to your collection!'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding plant: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Custom Tab Bar
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFDCECD7), // Light green background to match the home page
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1A2B48), // Navy blue text for selected tab
              unselectedLabelColor: Colors.grey.shade700,
              indicatorColor: const Color(0xFF8BC34A), // Green indicator
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(
                  text: 'Available Plants',
                  icon: Icon(Icons.eco_outlined),
                ),
                Tab(
                  text: 'My Collection',
                  icon: Icon(Icons.local_florist),
                ),
              ],
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAvailablePlantsTab(),
                _buildSavedPlantsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailablePlantsTab() {
    return FutureBuilder<List<dynamic>>(
      future: _plantsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF8BC34A), // Green color to match app theme
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade300, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, color: Colors.grey.shade400, size: 60),
                const SizedBox(height: 16),
                Text(
                  'No plants found for your area.',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        final plants = snapshot.data!;
        return StreamBuilder<List<Plant>>(
          stream: _userPlantsStream,
          builder: (context, userPlantsSnapshot) {
            final userPlants = userPlantsSnapshot.data ?? [];
            
            return Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: plants.length,
                itemBuilder: (context, index) {
                  final plant = plants[index];
                  final commonName = plant['common_name'] ?? 'Unknown Plant';
                  
                  // Check if plant is already in collection
                  final bool isInCollection = userPlants.any((p) => 
                    p.name.toLowerCase() == commonName.toLowerCase());
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          // Plant Image
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCECD7), // Light green background
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: (plant['default_image'] != null &&
                                      plant['default_image']['thumbnail'] != null)
                                  ? Image.network(
                                      plant['default_image']['thumbnail'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.image_not_supported, color: Colors.grey),
                                    )
                                  : const Icon(Icons.image_not_supported, color: Colors.grey),
                            ),
                          ),
                          
                          // Plant Details
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    commonName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF1A2B48), // Navy blue text
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    plant['scientific_name']?.join(', ') ?? 'No scientific name',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Add Button
                          ElevatedButton(
                            onPressed: isInCollection ? null : () => _savePlant(plant),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isInCollection 
                                ? Colors.grey.shade300 
                                : const Color(0xFF8BC34A), // Green button
                              foregroundColor: isInCollection 
                                ? Colors.grey.shade700
                                : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              minimumSize: const Size(40, 40),
                              padding: const EdgeInsets.all(0),
                            ),
                            child: Icon(isInCollection ? Icons.check : Icons.add),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildSavedPlantsTab() {
    final userId = authService.userId ?? 'test_user';
    
    return StreamBuilder<List<Plant>>(
      stream: firebaseService.getUserPlants(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade300, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF8BC34A), // Green color to match app theme
            ),
          );
        }

        final savedPlants = snapshot.data ?? [];
        if (savedPlants.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.spa_outlined, color: Colors.grey.shade400, size: 60),
                const SizedBox(height: 16),
                Text(
                  'No plants in your collection yet',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Browse available plants and add some!',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: savedPlants.length,
            itemBuilder: (context, index) {
              final plant = savedPlants[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      // Plant Image
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCECD7), // Light green background
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: plant.imageUrl != null
                              ? Image.network(
                                  plant.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.image_not_supported, color: Colors.grey),
                                )
                              : const Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                      ),
                      
                      // Plant Details
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plant.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF1A2B48), // Navy blue text
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8BC34A).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      plant.growthStage,
                                      style: const TextStyle(
                                        color: Color(0xFF558B2F),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.favorite,
                                    color: Colors.red.shade400,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${plant.healthStatus}%',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Delete Button
                      IconButton(
                        onPressed: () {
                          // Show confirmation dialog
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Remove Plant?'),
                              content: Text('Are you sure you want to remove ${plant.name} from your collection?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('CANCEL'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    firebaseService.deletePlant(userId, plant.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${plant.name} removed from your collection'),
                                        backgroundColor: Colors.grey.shade700,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    );
                                  },
                                  child: const Text('REMOVE', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}