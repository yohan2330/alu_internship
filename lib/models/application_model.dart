import 'package:cloud_firestore/cloud_firestore.dart';

class ApplicationModel {
  final String id;
  final String internshipId;
  final String internshipTitle;
  final String company;
  final String applicantId;
  final String status; // "pending", "accepted", "rejected"
  final DateTime? appliedAt;

  ApplicationModel({
    required this.id,
    required this.internshipId,
    required this.internshipTitle,
    required this.company,
    required this.applicantId,
    required this.status,
    this.appliedAt,
  });

  static ApplicationModel fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final timestamp = data['appliedAt'];

    return ApplicationModel(
      id: doc.id,
      internshipId: data['internshipId'] as String? ?? '',
      internshipTitle: data['internshipTitle'] as String? ?? '',
      company: data['company'] as String? ?? '',
      applicantId: data['applicantId'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      appliedAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}
