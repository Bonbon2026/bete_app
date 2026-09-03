import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'post_listing_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

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
      body: Center(child: Text('Logged in as: ${user?.email ?? "unknown"}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const PostListingScreen()));
        },
        icon: const Icon(Icons.add_home_outlined),
        label: const Text('Post a Listing'),
      ),
    );
  }
}
