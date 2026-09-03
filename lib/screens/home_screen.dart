import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'browse_screen.dart';
import 'post_listing_screen.dart';
import 'complete_profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bete'),
        actions: [
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
