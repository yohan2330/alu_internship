import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import 'add_internship_page.dart' show kCategories;

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredInternshipsProvider);
    final authService = ref.read(authServiceProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final bookmarkedIds = ref.watch(bookmarkedIdsProvider).value ?? <String>{};
    final uid = ref.watch(authStateProvider).value?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("ALU Internship"),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            tooltip: 'Saved',
            onPressed: () => context.push('/bookmarks'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Post an opportunity',
            onPressed: () => context.push('/addInternship'),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF002147)),
              child: Center(
                child: Text(
                  "ALU Internship",
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () => context.go('/home'),
            ),
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text("My Startup"),
              onTap: () => context.go('/organization'),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_outline),
              title: const Text("Saved Opportunities"),
              onTap: () => context.go('/bookmarks'),
            ),
            ListTile(
              leading: const Icon(Icons.assignment_turned_in),
              title: const Text("My Applications"),
              onTap: () => context.go('/applications'),
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text("Chat"),
              onTap: () => context.go('/chat'),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profile"),
              onTap: () => context.go('/profile'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Log out"),
              onTap: () async {
                await authService.signOut();
                // AuthGate reacts automatically and shows LoginPage.
              },
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: "Search roles, startups, or skills",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: kCategories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = kCategories[index];
                final selected = cat == selectedCategory;
                return ChoiceChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) =>
                      ref.read(selectedCategoryProvider.notifier).state = cat,
                  selectedColor: const Color(0xFF002147),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredAsync.when(
              data: (internships) {
                if (internships.isEmpty) {
                  return const Center(child: Text("No opportunities match your search."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: internships.length,
                  itemBuilder: (context, index) {
                    final internship = internships[index];
                    final isSaved = bookmarkedIds.contains(internship.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF002147).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.business, color: Color(0xFF002147)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        internship.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.verified,
                                              size: 14, color: Colors.blue.shade600),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              "${internship.company} • ${internship.location}",
                                              style: TextStyle(color: Colors.grey.shade700),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                                    color: isSaved ? const Color(0xFF002147) : Colors.grey,
                                  ),
                                  onPressed: uid == null
                                      ? null
                                      : () => ref
                                          .read(firestoreServiceProvider)
                                          .toggleBookmark(uid, internship.id, !isSaved),
                                ),
                              ],
                            ),
                            if (internship.skills.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: internship.skills
                                    .map((s) => Chip(
                                          label: Text(s, style: const TextStyle(fontSize: 12)),
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                          backgroundColor: Colors.grey.shade100,
                                        ))
                                    .toList(),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (uid == null) return;

                                  await ref
                                      .read(firestoreServiceProvider)
                                      .applyToInternship(
                                        applicantId: uid,
                                        internship: internship,
                                      );

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Applied to ${internship.title}"),
                                      ),
                                    );
                                  }
                                },
                                child: const Text("Apply"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text("Something went wrong: $error")),
            ),
          ),
        ],
      ),
    );
  }
}