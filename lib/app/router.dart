import 'package:go_router/go_router.dart';

import '../screens/auth_gate.dart';
import '../screens/register_page.dart';
import '../screens/home_page.dart';
import '../screens/add_internship_page.dart';
import '../screens/applications_page.dart';
import '../screens/profile_page.dart';
import '../screens/chat_page.dart';
import '../screens/conversation_page.dart';
import '../screens/organization_page.dart';
import '../screens/bookmarks_page.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    // AuthGate decides, based on live auth state, whether to render
    // LoginPage or HomePage. This is the ONLY entry point, so it's
    // impossible to land on /home with a null/unresolved user — which is
    // what caused the earlier "Unexpected null value" crashes.
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthGate(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/applications',
      builder: (context, state) => const ApplicationsPage(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/organization',
      builder: (context, state) => const OrganizationPage(),
    ),
    GoRoute(
      path: '/bookmarks',
      builder: (context, state) => const BookmarksPage(),
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) => const ChatPage(),
    ),
    GoRoute(
      path: '/chat/:otherUserId',
      builder: (context, state) {
        final otherUserId = state.pathParameters['otherUserId']!;
        final otherUserName = (state.extra as String?) ?? 'Chat';
        return ConversationPage(
          otherUserId: otherUserId,
          otherUserName: otherUserName,
        );
      },
    ),
    // Reached via context.push() so it always has something to pop back to.
    GoRoute(
      path: '/addInternship',
      builder: (context, state) => const AddInternshipPage(),
    ),
  ],
);
