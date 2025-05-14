class AppUser {
  final String uid;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? photoURL;
  final int coins;
  final DateTime createdAt;
  final DateTime lastLogin;
  
  AppUser({
    required this.uid,
    required this.email,
    this.firstName,
    this.lastName,
    this.photoURL,
    this.coins = 0,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    lastLogin = lastLogin ?? DateTime.now();
  
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'photoURL': photoURL,
      'coins': coins,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLogin': lastLogin.millisecondsSinceEpoch,
    };
  }
  
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'],
      email: map['email'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      photoURL: map['photoURL'],
      coins: map['coins'] ?? 0,
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt']) 
          : null,
      lastLogin: map['lastLogin'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastLogin']) 
          : null,
    );
  }
  
  AppUser copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    String? photoURL,
    int? coins,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      photoURL: photoURL ?? this.photoURL,
      coins: coins ?? this.coins,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
  
  // Utility method to get first name only
  String get firstNameOnly {
    return firstName ?? (email?.split('@').first) ?? 'User';
  }
}