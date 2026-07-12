import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Shared category taxonomy for organizations and opportunities, so the
/// filter chips on the discovery feed always match what founders can
/// actually pick when posting.
const List<String> kCategories = [
  'All',
  'Software Development',
  'Design',
  'Marketing',
  'Operations',
  'Research',
  'Business Analysis',
  'Content Creation',
  'Community Management',
];

class AddInternshipPage extends ConsumerStatefulWidget {
  const AddInternshipPage({super.key});

  @override
  ConsumerState<AddInternshipPage> createState() => _AddInternshipPageState();
}

class _AddInternshipPageState extends ConsumerState<AddInternshipPage> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final skillsController = TextEditingController();
  String category = kCategories[1];
  bool saving = false;

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    skillsController.dispose();
    super.dispose();
  }

  Future<void> saveInternship(String organizationId, String company) async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (saving) return;

    setState(() => saving = true);

    final skills = skillsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    try {
      await ref.read(firestoreServiceProvider).addInternship(
            company: company,
            title: titleController.text.trim(),
            description: descriptionController.text.trim(),
            location: locationController.text.trim(),
            organizationId: organizationId,
            category: category,
            skills: skills,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Internship posted")),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not save internship: $e")),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgAsync = ref.watch(myOrganizationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Post an Opportunity"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: orgAsync.when(
        data: (org) {
          // No org registered yet at all.
          if (org == null) {
            return _blocked(
              icon: Icons.storefront_outlined,
              message: "You need to register your startup before posting "
                  "opportunities.",
              buttonLabel: "Register startup",
              onPressed: () => context.push('/organization'),
            );
          }
          // Org registered but not yet verified by ALU — this is the check
          // that enforces "only recognized ALU startups" at write-time.
          if (!org.verified) {
            return _blocked(
              icon: Icons.hourglass_top,
              message: "\"${org.name}\" is still pending ALU verification. "
                  "You can post opportunities once it's approved.",
              buttonLabel: "View status",
              onPressed: () => context.push('/organization'),
            );
          }
          return _buildForm(org.id, org.name);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text("Something went wrong: $error")),
      ),
    );
  }

  Widget _blocked({
    required IconData icon,
    required String message,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade500),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(String organizationId, String company) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Role title"),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Title is required" : null,
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(labelText: "Category"),
              items: kCategories
                  .where((c) => c != 'All')
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => category = v ?? category),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 4,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Description is required" : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: locationController,
              decoration: const InputDecoration(labelText: "Location (e.g. Remote, Kigali)"),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Location is required" : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: skillsController,
              decoration: const InputDecoration(
                labelText: "Skills needed (comma-separated)",
                hintText: "Flutter, UI Design, Copywriting",
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: saving ? null : () => saveInternship(organizationId, company),
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text("Post opportunity"),
            ),
          ],
        ),
      ),
    );
  }
}