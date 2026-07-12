import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

class BookmarksPage extends ConsumerWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final internshipsAsync = ref.watch(internshipsProvider);
    final bookmarkedIdsAsync = ref.watch(bookmarkedIdsProvider);
    final uid = ref.watch(authStateProvider).value?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Saved Opportunities")),
      body: internshipsAsync.when(
        data: (internships) {
          final bookmarkedIds = bookmarkedIdsAsync.value ?? <String>{};
          final saved = internships.where((i) => bookmarkedIds.contains(i.id)).toList();

          if (saved.isEmpty) {
            return const Center(child: Text("You haven't saved any opportunities yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: saved.length,
            itemBuilder: (context, index) {
              final internship = saved[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.bookmark, color: Color(0xFF002147)),
                  title: Text(internship.title),
                  subtitle: Text("${internship.company} • ${internship.location}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.bookmark_remove_outlined),
                    onPressed: uid == null
                        ? null
                        : () => ref
                            .read(firestoreServiceProvider)
                            .toggleBookmark(uid, internship.id, false),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text("Something went wrong: $error")),
      ),
    );
  }
}