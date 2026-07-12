import 'package:cloud_firestore/cloud_firestore.dart';

class InternshipModel {
  final String id;
  final String title;
  final String company;
  final String description;
  final String location;
  final String organizationId; // links back to the verified org that posted it
  final String category;
  final List<String> skills;
  final DateTime? createdAt;

  InternshipModel({
    required this.id,
    required this.title,
    required this.company,
    required this.description,
    required this.location,
    required this.organizationId,
    required this.category,
    required this.skills,
    this.createdAt,
  });

  static InternshipModel fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final timestamp = data['createdAt'];

    return InternshipModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      company: data['company'] as String? ?? '',
      description: data['description'] as String? ?? '',
      location: data['location'] as String? ?? '',
      organizationId: data['organizationId'] as String? ?? '',
      category: data['category'] as String? ?? 'General',
      skills: (data['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}
