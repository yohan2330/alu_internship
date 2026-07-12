import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String role; // "student" or "startup"

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
  });

  /// Builds a UserModel from a Firestore document. Returns null if the
  /// document doesn't exist or has no data — callers should handle null
  /// instead of assuming the profile is always there (this is what caused
  /// the earlier "Unexpected null value" crashes).
  static UserModel? fromDoc(DocumentSnapshot doc) {
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return null;

    return UserModel(
      uid: data['uid'] as String? ?? doc.id,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'role': role,
    };
  }
}
