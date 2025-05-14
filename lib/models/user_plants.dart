class Plant {
  final String id;
  final String name;
  final String? imageUrl;
  final String? careInstructions;
  final DateTime addedDate;
  final int healthStatus; // 0-100
  final int waterLevel; // 0-100
  final int fertilizeLevel; // 0-100
  final String growthStage; // seed, sprout, mature, etc.
  
  Plant({
    required this.id,
    required this.name,
    this.imageUrl,
    this.careInstructions,
    DateTime? addedDate,
    this.healthStatus = 100,
    this.waterLevel = 100,
    this.fertilizeLevel = 100,
    this.growthStage = 'seed',
  }) : addedDate = addedDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'careInstructions': careInstructions,
      'addedDate': addedDate.millisecondsSinceEpoch,
      'healthStatus': healthStatus,
      'waterLevel': waterLevel,
      'fertilizeLevel': fertilizeLevel,
      'growthStage': growthStage,
    };
  }

  factory Plant.fromMap(Map<String, dynamic> map) {
    return Plant(
      id: map['id'],
      name: map['name'],
      imageUrl: map['imageUrl'],
      careInstructions: map['careInstructions'],
      addedDate: map['addedDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['addedDate']) 
          : null,
      healthStatus: map['healthStatus'] ?? 100,
      waterLevel: map['waterLevel'] ?? 100,
      fertilizeLevel: map['fertilizeLevel'] ?? 100,
      growthStage: map['growthStage'] ?? 'seed',
    );
  }
}