import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

class AppUser extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String? image;

  final bool? notifications;
  final bool? darkMode;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  final int? plantPassion;
  final String? location;
  final String? experienceLevel;
  final List<String>? preferredPlants;
  final bool? hasPet;
  final String? timezone;
  final String? language;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.image,
    this.notifications,
    this.darkMode,
    this.createdAt,
    this.lastLogin,
    this.plantPassion,
    this.location,
    this.experienceLevel,
    this.preferredPlants,
    this.hasPet,
    this.timezone,
    this.language,
  });

  /// Firebase User → AppUser 변환
  factory AppUser.fromFirebaseUser(firebase.User user, Map<String, dynamic> firestoreData) {
    return AppUser(
      id: user.uid,
      fullName: firestoreData['fullName'] ?? '', // Firebase User에는 없으므로 비워둠
      email: user.email ?? '',
      image: user.photoURL,
      createdAt: user.metadata.creationTime,
      lastLogin: user.metadata.lastSignInTime,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      image: json['image'],
      notifications: json['notifications'],
      darkMode: json['darkMode'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      lastLogin: json['lastLogin'] != null ? DateTime.tryParse(json['lastLogin']) : null,
      plantPassion: json['plantPassion'],
      location: json['location'],
      experienceLevel: json['experienceLevel'],
      preferredPlants: json['preferredPlants'] != null
          ? List<String>.from(json['preferredPlants'])
          : null,
      hasPet: json['hasPet'],
      timezone: json['timezone'],
      language: json['language'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'image': image,
      'notifications': notifications,
      'darkMode': darkMode,
      'createdAt': createdAt?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'plantPassion': plantPassion,
      'location': location,
      'experienceLevel': experienceLevel,
      'preferredPlants': preferredPlants,
      'hasPet': hasPet,
      'timezone': timezone,
      'language': language,
    };
  }

  @override
  List<Object?> get props => [
    id,
    fullName,
    email,
    image,
    notifications,
    darkMode,
    createdAt,
    lastLogin,
    plantPassion,
    location,
    experienceLevel,
    preferredPlants,
    hasPet,
    timezone,
    language,
  ];
}
