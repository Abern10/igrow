import 'dart:math';
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../models/user_plants.dart';
import 'plant_provider.dart';
import 'shop_page.dart'; // Import for navigation to the shop page
import 'main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Future that fetches real API data for "New plants in town"
  late Future<List<dynamic>> _newPlantsFuture;
  late Stream<List<Plant>> _userPlantsStream;
  final FirebaseService firebaseService = FirebaseService();
  final PlantProvider plantProvider = PlantProvider();
  final AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
    _newPlantsFuture = plantProvider.getPlants();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = authService.userId ?? 'test_user';
    _userPlantsStream = firebaseService.getUserPlants(userId);
  }

  // Function to navigate to the shop page's collection tab
  void _navigateToShop(BuildContext context) {
    // Use the global key to access the main page state and switch to the shop tab (index 2)
    MainPage.mainPageKey.currentState?.switchToTab(2);
  }

  // Function to add plant to collection
  Future<void> _addToCollection(Map<String, dynamic> plantData) async {
    try {
      final userId = authService.userId ?? 'test_user';
      
      // Create plant object from API data
      final plant = Plant(
        id: DateTime.now().toString(), // Consider using UUID for production
        name: plantData['common_name'] ?? 'Unknown Plant',
        imageUrl: plantData['default_image']?['thumbnail'],
        careInstructions: plantData['scientific_name']?.join(', '),
      );
      
      // Save to Firebase
      await firebaseService.savePlant(userId, plant);
      
      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${plant.name} added to your collection!'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      
    } catch (e) {
      // Show error message
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------------------------------------------
          // CURRENT PLANTS (Horizontal scrolling grid)
          // ---------------------------------------------------
          Text(
            "Current plants",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 10),

          StreamBuilder<List<Plant>>(
            stream: _userPlantsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingCurrentPlants();
              } else if (snapshot.hasError) {
                return _buildErrorCurrentPlants(snapshot.error);
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyCurrentPlants();
              } else {
                final plants = snapshot.data!;
                return _buildCurrentPlantsGrid(plants);
              }
            },
          ),

          const SizedBox(height: 20),

          // ---------------------------------------------------
          // NEW PLANTS IN TOWN (Dynamic API, 2-column grid)
          // ---------------------------------------------------
          Text(
            "New plants in town",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 10),

          // Green background container for the grid
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFDCECD7), // Light green background
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(12),
            child: FutureBuilder<List<dynamic>>(
              future: _newPlantsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF8BC34A),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade300, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, color: Colors.grey.shade600, size: 40),
                        const SizedBox(height: 12),
                        const Text(
                          "No new plants available.",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                } else {
                  // We have live data from the API
                  final List<dynamic> apiPlants = snapshot.data!;

                  // Shuffle and limit to 6 plants
                  final random = Random();
                  apiPlants.shuffle(random);
                  final randomSix = apiPlants.take(6).toList();

                  // Display in a uniform grid
                  return _buildUniformPlantGrid(randomSix);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------
  // UNIFORM GRID FOR NEW PLANTS
  // ---------------------------------------------------
  Widget _buildUniformPlantGrid(List<dynamic> plants) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: plants.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75, // Fixed aspect ratio for all cards
      ),
      itemBuilder: (context, index) {
        final plant = plants[index];
        return _buildNewPlantCard(plant);
      },
    );
  }

  // ---------------------------------------------------
  // CURRENT PLANTS SECTION (Horizontal scrolling grid)
  // ---------------------------------------------------
  
  // Loading state
  Widget _buildLoadingCurrentPlants() {
    return Container(
      height: 300, // Fixed height for the container
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF8BC34A),
        ),
      ),
    );
  }
  
  // Error state
  Widget _buildErrorCurrentPlants(dynamic error) {
    return Container(
      height: 300, // Fixed height for the container
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
              const SizedBox(height: 16),
              Text(
                "Error loading plants: $error",
                style: const TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Empty state
  Widget _buildEmptyCurrentPlants() {
    return Container(
      height: 300, // Fixed height for the container
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.spa_outlined, color: Colors.grey.shade400, size: 48),
            const SizedBox(height: 16),
            Text(
              "You have no plants.",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Visit the shop to add plants to your collection",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _navigateToShop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8BC34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Browse Plants'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Grid with plants
  Widget _buildCurrentPlantsGrid(List<Plant> plants) {
    // Calculate how many columns we need
    // Each column can display up to 3 plants
    final int totalColumns = (plants.length / 3).ceil();
    
    return Container(
      height: 380, // Fixed height for the container
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: totalColumns,
          itemBuilder: (context, columnIndex) {
            final int startIndex = columnIndex * 3;
            // Calculate how many plants to show in this column (up to 3)
            final int itemsInThisColumn = min(3, plants.length - startIndex);
            
            return Container(
              width: 300, // Fixed width for each column
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: List.generate(
                  itemsInThisColumn,
                  (rowIndex) {
                    final int plantIndex = startIndex + rowIndex;
                    return _buildPlantCard(plants[plantIndex]);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  // Individual plant card
  Widget _buildPlantCard(Plant plant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
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
              width: 60,
              height: 60,
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
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1A2B48), // Navy blue text
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8BC34A).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            plant.growthStage,
                            style: const TextStyle(
                              color: Color(0xFF558B2F),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
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
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.water_drop,
                          color: Colors.blue.shade400,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${plant.waterLevel}%',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------
  // NEW PLANT CARD (Fetched from API, Random 6)
  // ---------------------------------------------------
  Widget _buildNewPlantCard(dynamic plant) {
    final commonName = plant['common_name'] ?? 'Unknown Plant';
    final scientific = plant['scientific_name']?.join(', ') ?? '';
    final imageUrl = (plant['default_image'] != null &&
            plant['default_image']['thumbnail'] != null)
        ? plant['default_image']['thumbnail']
        : null;

    // Check if plant is already in collection
    return StreamBuilder<List<Plant>>(
      stream: _userPlantsStream,
      builder: (context, snapshot) {
        bool isInCollection = false;
        
        // Check if this plant is already in the user's collection
        if (snapshot.hasData && snapshot.data != null) {
          isInCollection = snapshot.data!.any((p) => 
            p.name.toLowerCase() == commonName.toLowerCase());
        }
        
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8F2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Plant image (only show if available)
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.image_not_supported,
                                size: 30,
                                color: Colors.grey,
                              ),
                        )
                      : const Icon(
                          Icons.image_not_supported,
                          size: 30,
                          color: Colors.grey,
                        ),
                  ),
                ),
    
                const SizedBox(height: 12),
    
                // Common name
                Text(
                  commonName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2B48),
                  ),
                ),
    
                const SizedBox(height: 6),
    
                // Scientific name
                if (scientific.isNotEmpty)
                  Text(
                    scientific,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  
                // Add to collection button  
                const SizedBox(height: 8),
                
                // Button changes based on whether plant is already in collection
                GestureDetector(
                  onTap: isInCollection ? null : () => _addToCollection(plant),
                  child: Container(
                    height: 30,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isInCollection 
                        ? Colors.grey.shade300 
                        : const Color(0xFF8BC34A).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        isInCollection ? 'In Collection' : 'Add to Collection',
                        style: TextStyle(
                          color: isInCollection 
                            ? Colors.grey.shade700
                            : const Color(0xFF558B2F),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}