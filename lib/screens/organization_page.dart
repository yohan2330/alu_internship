import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import 'add_internship_page.dart' show kCategories;

/// Lets a startup founder register their venture. The org starts
/// unverified — this screen makes that state visible (banner) so the
/// student understands why they can't post internships yet, instead of
/// silently failing. Verification itself happens on the admin side
/// (Firebase Console, or setOrganizationVerified in FirestoreService).
class OrganizationPage extends ConsumerStatefulWidget {
  const OrganizationPage({super.key});

  @override
  ConsumerState<OrganizationPage> createState() => _OrganizationPageState();
}

class _OrganizationPageState extends ConsumerState<OrganizationPage> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final emailController = TextEditingController();
  String category = kCategories.first;
  bool saving = false;

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null || saving) return;

    setState(() => saving = true);
    try {
      await ref.read(firestoreServiceProvider).createOrganization(
            ownerId: uid,
            name: nameController.text.trim(),
            description: descriptionController.text.trim(),
            category: category,
            contactEmail: emailController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Startup profile submitted — pending ALU verification"),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not save profile: $e")),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgAsync = ref.watch(myOrganizationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("My Startup")),
      body: orgAsync.when(
        data: (org) {
          if (org == null) return _buildForm();
          return _buildProfile(org.name, org.description, org.category,
              org.contactEmail, org.verified);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text("Something went wrong: $error")),
      ),
    );
  }

  Widget _buildProfile(String name, String description, String category,
      String email, bool verified) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: verified
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: verified ? Colors.green : Colors.orange,
            ),
          ),
          child: Row(
            children: [
              Icon(
                verified ? Icons.verified : Icons.hourglass_top,
                color: verified ? Colors.green.shade700 : Colors.orange.shade700,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  verified
                      ? "Verified by ALU — you can post opportunities."
                      : "Pending ALU verification. You'll be able to post "
                          "opportunities once an admin approves your startup.",
                  style: TextStyle(
                    color: verified ? Colors.green.shade800 : Colors.orange.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Chip(label: Text(category)),
        const SizedBox(height: 16),
        Text(description, style: const TextStyle(fontSize: 15, height: 1.4)),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.email_outlined, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Text(email),
          ],
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: ListView(
          children: [
            const Text(
              "Register your startup",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              "Your profile is reviewed by ALU before you can post opportunities.",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Startup name"),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Name is required" : null,
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
              decoration: const InputDecoration(labelText: "What does your startup do?"),
              maxLines: 4,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Description is required" : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: "Contact email"),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Contact email is required" : null,
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: saving ? null : register,
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text("Submit for verification"),
            ),
          ],
        ),
      ),
    );
  }
}