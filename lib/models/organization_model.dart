import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a student-led startup / venture profile.
///
/// Only organizations with [verified] == true are allowed to appear as the
/// poster of an internship on the discovery feed. This is what enforces the
/// "only valid startups recognized at ALU" requirement — verification is a
/// deliberate manual step (an ALU staff/admin flips this flag in Firestore
/// or via the simple admin toggle in this app), not something a startup can
/// grant itself.
class OrganizationModel {
  final String id;
  final String name;
  final String description;
  final String category; // e.g. "Tech", "Agriculture", "Education"
  final String contactEmail;
  final String ownerId; // uid of the student who registered the startup
  final bool verified;
  final DateTime? createdAt;

  OrganizationModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.contactEmail,
    required this.ownerId,
    required this.verified,
    this.createdAt,
  });

  static OrganizationModel? fromDoc(DocumentSnapshot doc) {
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return null;
    final timestamp = data['createdAt'];

    return OrganizationModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? 'General',
      contactEmail: data['contactEmail'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      verified: data['verified'] as bool? ?? false,
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}