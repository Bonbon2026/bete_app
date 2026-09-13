import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/listing.dart';
import 'listing_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Listing> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      final favoriteRows = await supabase
          .from('favorites')
          .select('listing_id')
          .eq('user_id', userId);

      final listings = <Listing>[];
      for (final row in favoriteRows as List) {
        final listingId = row['listing_id'] as String;
        final listingData = await supabase
            .from('listings')
            .select()
            .eq('id', listingId)
            .maybeSingle();
        if (listingData == null) continue;

        final mediaData = await supabase
            .from('media')
            .select('url')
            .eq('listing_id', listingId)
            .order('sort_order');
        final photoUrls = (mediaData as List)
            .map((m) => m['url'] as String)
            .toList();

        listings.add(Listing.fromMap(listingData, photoUrls));
      }

      setState(() {
        _favorites = listings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Favorites')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
          ? const Center(child: Text('No favorites yet'))
          : RefreshIndicator(
              onRefresh: _loadFavorites,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _favorites.length,
                itemBuilder: (context, index) {
                  final listing = _favorites[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      leading: listing.photoUrls.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                listing.photoUrls.first,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.home_outlined),
                      title: Text(listing.title),
                      subtitle: Text(
                        '${listing.neighborhood} • ${listing.price.toStringAsFixed(0)} ETB',
                      ),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ListingDetailScreen(listing: listing),
                          ),
                        );
                        _loadFavorites();
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
