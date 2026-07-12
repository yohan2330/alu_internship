import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/user_model.dart';
import '../models/internship_model.dart';
import '../models/application_model.dart';
import '../models/organization_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

// ---------------------------------------------------------------------
// SERVICES (single shared instance for the whole app)
// ---------------------------------------------------------------------

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

// ---------------------------------------------------------------------
// AUTH STATE
// ---------------------------------------------------------------------

/// The single source of truth for "is someone logged in right now".
/// AuthGate (see screens/auth_gate.dart) watches this to decide whether to
/// show LoginPage or HomePage — nothing else in the app should read
/// FirebaseAuth.instance.currentUser directly.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// The current user's Firestore profile document (name, email, role),
/// re-fetched whenever the logged-in uid changes. Any screen can watch
/// this instead of duplicating a FutureBuilder + getUser() call.
final currentUserProfileProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) async {
      if (user == null) return null;
      return ref.read(firestoreServiceProvider).getUser(user.uid);
    },
    loading: () async => null,
    error: (err, stack) async => null,
  );
});

// ---------------------------------------------------------------------
// INTERNSHIPS
// ---------------------------------------------------------------------

final internshipsProvider = StreamProvider<List<InternshipModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getInternships();
});

// ---------------------------------------------------------------------
// APPLICATIONS (for the currently logged-in user)
// ---------------------------------------------------------------------

final myApplicationsProvider = StreamProvider<List<ApplicationModel>>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      return ref.watch(firestoreServiceProvider).getApplicationsForUser(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (err, stack) => const Stream.empty(),
  );
});

// ---------------------------------------------------------------------
// ORGANIZATIONS
// ---------------------------------------------------------------------

/// The logged-in user's own startup profile, if they've registered one.
/// Null (not loading forever) means "hasn't registered a startup yet" —
/// the Organization screen uses that to decide whether to show a
/// registration form or the existing profile + verification status.
final myOrganizationProvider = StreamProvider<OrganizationModel?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(firestoreServiceProvider).getMyOrganization(user.uid);
    },
    loading: () => Stream.value(null),
    error: (err, stack) => Stream.value(null),
  );
});

final allOrganizationsProvider = StreamProvider<List<OrganizationModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getAllOrganizations();
});

// ---------------------------------------------------------------------
// DISCOVERY: SEARCH + CATEGORY FILTER
// ---------------------------------------------------------------------

final searchQueryProvider = StateProvider<String>((ref) => '');

/// 'All' means no category filter applied.
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

/// Derives the filtered feed from the live internships stream plus the two
/// filter providers above. Because this reads other providers with `watch`,
/// it recomputes automatically whenever the search text, category, or
/// underlying Firestore data changes — no manual refresh needed anywhere.
final filteredInternshipsProvider = Provider<AsyncValue<List<InternshipModel>>>((ref) {
  final internshipsAsync = ref.watch(internshipsProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final category = ref.watch(selectedCategoryProvider);

  return internshipsAsync.whenData((internships) {
    return internships.where((i) {
      final matchesCategory = category == 'All' || i.category == category;
      final matchesQuery = query.isEmpty ||
          i.title.toLowerCase().contains(query) ||
          i.company.toLowerCase().contains(query) ||
          i.skills.any((s) => s.toLowerCase().contains(query));
      return matchesCategory && matchesQuery;
    }).toList();
  });
});

// ---------------------------------------------------------------------
// BOOKMARKS
// ---------------------------------------------------------------------

final bookmarkedIdsProvider = StreamProvider<Set<String>>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(<String>{});
      return ref.watch(firestoreServiceProvider).getBookmarkedIds(user.uid);
    },
    loading: () => Stream.value(<String>{}),
    error: (err, stack) => Stream.value(<String>{}),
  );
});

// ---------------------------------------------------------------------
// CHAT CONTACTS
// ---------------------------------------------------------------------

final chatContactsProvider = StreamProvider<List<UserModel>>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      return ref.watch(firestoreServiceProvider).getAllUsersExcept(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (err, stack) => const Stream.empty(),
  );
});