import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

class ChatPage extends ConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(chatContactsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Chat")),
      body: contactsAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text("No other users yet."));
          }

          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = users[index];

              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : "?",
                  ),
                ),
                title: Text(user.fullName),
                subtitle: Text(user.role),
                onTap: () {
                  context.push('/chat/${user.uid}', extra: user.fullName);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text("Something went wrong: $error")),
      ),
    );
  }
}
