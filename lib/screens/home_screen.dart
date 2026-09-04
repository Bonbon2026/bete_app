import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'browse_screen.dart';
import 'post_listing_screen.dart';
import 'complete_profile_screen.dart';
import 'admin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;
      final profile = await supabase
          .from('profiles')
          .select('is_admin')
          .eq('id', userId)
          .maybeSingle();
      if (mounted) {
        setState(() => _isAdmin = profile?['is_admin'] == true);
      }
    } catch (_) {
      // not an admin, or no profile yet — stays false
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bete'),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              tooltip: 'Admin',
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const AdminScreen()));
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: const BrowseScreen(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final supabase = Supabase.instance.client;
          final userId = supabase.auth.currentUser!.id;

          final profile = await supabase
              .from('profiles')
              .select()
              .eq('id', userId)
              .maybeSingle();

          final hasPhone =
              profile != null &&
              profile['phone'] != null &&
              (profile['phone'] as String).isNotEmpty;

          if (!hasPhone) {
            final completed = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
            );
            if (completed != true) return;
          }

          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PostListingScreen()),
            );
          }
        },
        icon: const Icon(Icons.add_home_outlined),
        label: const Text('Post a Listing'),
      ),
    );
  }
}
