import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final authUser = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: profileAsync.when(
        data: (profile) {
          final fullName = profile?.fullName ?? authUser?.email ?? "Student";
          final email = profile?.email ?? authUser?.email ?? "";
          final role = profile?.role ?? "";

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 60,
                  child: Icon(Icons.person, size: 70),
                ),
                const SizedBox(height: 20),
                Text(fullName, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 10),
                Text(email),
                if (role.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(role, style: TextStyle(color: Colors.grey.shade600)),
                ],
                if (profile == null) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      "No profile document found in Firestore for this account yet.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
                  ),
                ],
                const SizedBox(height: 30),
                if (role == 'startup')
                  OutlinedButton.icon(
                    onPressed: () => context.push('/organization'),
                    icon: const Icon(Icons.storefront_outlined),
                    label: const Text("My Startup Profile"),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => context.push('/bookmarks'),
                    icon: const Icon(Icons.bookmark_outline),
                    label: const Text("Saved Opportunities"),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text("Something went wrong: $error")),
      ),
    );
  }
}
