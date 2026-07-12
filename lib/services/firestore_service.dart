import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../models/internship_model.dart';
import '../models/application_model.dart';
import '../models/organization_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------
  // USERS
  // ---------------------------------------------------------------------

  Future<void> saveUser({
    required String uid,
    required String fullName,
    required String email,
    required String role,
  }) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Returns null (never throws) if the profile doc doesn't exist yet.
  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return UserModel.fromDoc(doc);
  }

  Stream<List<UserModel>> getAllUsersExcept(String currentUid) {
    return _db
        .collection('users')
        .where('uid', isNotEqualTo: currentUid)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => UserModel.fromDoc(doc))
            .whereType<UserModel>() // drops any malformed docs safely
            .toList());
  }

  // ---------------------------------------------------------------------
  // ORGANIZATIONS (startup / venture profiles)
  // ---------------------------------------------------------------------

  /// Registers a new startup profile. It starts unverified — it will not
  /// be able to post internships until an admin flips `verified` to true
  /// (either via verifyOrganization below or directly in the Firebase
  /// Console), which is what enforces "only recognized ALU startups".
  Future<void> createOrganization({
    required String ownerId,
    required String name,
    required String description,
    required String category,
    required String contactEmail,
  }) async {
    await _db.collection('organizations').add({
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'category': category,
      'contactEmail': contactEmail,
      'verified': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// A startup founder only ever has (at most) one organization doc — this
  /// stream drives the "My Organization" screen and reacts live if an
  /// admin verifies them while they're using the app.
  Stream<OrganizationModel?> getMyOrganization(String ownerId) {
    return _db
        .collection('organizations')
        .where('ownerId', isEqualTo: ownerId)
        .limit(1)
        .snapshots()
        .map((snap) =>
            snap.docs.isEmpty ? null : OrganizationModel.fromDoc(snap.docs.first));
  }

  Stream<List<OrganizationModel>> getAllOrganizations() {
    return _db
        .collection('organizations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map(OrganizationModel.fromDoc)
            .whereType<OrganizationModel>()
            .toList());
  }

  /// Simple admin-only action: toggles an organization's verified status.
  /// In a real deployment this would be gated behind Firestore security
  /// rules restricted to admin uids/custom claims.
  Future<void> setOrganizationVerified(String orgId, bool verified) async {
    await _db.collection('organizations').doc(orgId).update({
      'verified': verified,
    });
  }

  // ---------------------------------------------------------------------
  // INTERNSHIPS
  // ---------------------------------------------------------------------

  Stream<List<InternshipModel>> getInternships() {
    return _db
        .collection('internships')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(InternshipModel.fromDoc).toList());
  }

  Future<void> addInternship({
    required String company,
    required String title,
    required String description,
    required String location,
    required String organizationId,
    required String category,
    required List<String> skills,
  }) async {
    await _db.collection('internships').add({
      'company': company,
      'title': title,
      'description': description,
      'location': location,
      'organizationId': organizationId,
      'category': category,
      'skills': skills,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------
  // BOOKMARKS
  // ---------------------------------------------------------------------

  /// Stored as a subcollection under the user doc so it scales per-user
  /// instead of growing a single array field without bound.
  Future<void> toggleBookmark(String uid, String internshipId, bool bookmarked) async {
    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .doc(internshipId);

    if (bookmarked) {
      await ref.set({'createdAt': FieldValue.serverTimestamp()});
    } else {
      await ref.delete();
    }
  }

  Stream<Set<String>> getBookmarkedIds(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  // ---------------------------------------------------------------------
  // APPLICATIONS
  // ---------------------------------------------------------------------

  Future<void> applyToInternship({
    required String applicantId,
    required InternshipModel internship,
  }) async {
    // One application per (user, internship) pair — deterministic doc id
    // means tapping "Apply" twice updates the same doc instead of creating
    // duplicates.
    final docId = '${applicantId}_${internship.id}';

    await _db.collection('applications').doc(docId).set({
      'internshipId': internship.id,
      'internshipTitle': internship.title,
      'company': internship.company,
      'applicantId': applicantId,
      'status': 'pending',
      'appliedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ApplicationModel>> getApplicationsForUser(String uid) {
    return _db
        .collection('applications')
        .where('applicantId', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map(ApplicationModel.fromDoc).toList());
  }

  // ---------------------------------------------------------------------
  // CHAT
  // ---------------------------------------------------------------------

  String getChatId(String uidA, String uidB) {
    final ids = [uidA, uidB]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> ensureChatExists(String chatId, String uidA, String uidB) async {
    final chatRef = _db.collection('chats').doc(chatId);
    final snapshot = await chatRef.get();
    if (!snapshot.exists) {
      await chatRef.set({
        'participants': [uidA, uidB],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    final chatRef = _db.collection('chats').doc(chatId);

    await chatRef.collection('messages').add({
      'senderId': senderId,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await chatRef.update({
      'lastMessage': text.trim(),
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }

  /// Returns raw QuerySnapshot here since messages are simple and rendered
  /// directly — but still safely, with null checks, in conversation_page.dart.
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
