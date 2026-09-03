import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/listing.dart';
import 'listing_detail_screen.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  List<Listing> _listings = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _searchQuery = '';
  String _typeFilter = 'all'; // all, rent, sale
  double? _maxPrice;

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadListings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;

      final listingsData = await supabase
          .from('listings')
          .select()
          .eq('status', 'active')
          .order('created_at', ascending: false);

      final listings = <Listing>[];

      for (final row in listingsData as List) {
        final listingId = row['id'] as String;

        final mediaData = await supabase
            .from('media')
            .select('url')
            .eq('listing_id', listingId)
            .order('sort_order');

        final photoUrls = (mediaData as List)
            .map((m) => m['url'] as String)
            .toList();

        listings.add(Listing.fromMap(row, photoUrls));
      }

      setState(() {
        _listings = listings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load listings: $e';
        _isLoading = false;
      });
    }
  }

  List<Listing> get _filteredListings {
    return _listings.where((l) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          l.neighborhood.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          l.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesType = _typeFilter == 'all' || l.listingType == _typeFilter;
      final matchesPrice = _maxPrice == null || l.price <= _maxPrice!;
      return matchesSearch && matchesType && matchesPrice;
    }).toList();
  }

  void _showPriceFilterDialog() {
    final controller = TextEditingController(
      text: _maxPrice?.toStringAsFixed(0) ?? '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Max price (ETB)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'e.g. 30000'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _maxPrice = null);
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _maxPrice = double.tryParse(controller.text));
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredListings;

    return RefreshIndicator(
      onRefresh: _loadListings,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by neighborhood or title',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'all', label: Text('All')),
                          ButtonSegment(value: 'rent', label: Text('Rent')),
                          ButtonSegment(value: 'sale', label: Text('Sale')),
                        ],
                        selected: {_typeFilter},
                        onSelectionChanged: (selection) {
                          setState(() => _typeFilter = selection.first);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: _showPriceFilterDialog,
                      icon: Icon(
                        _maxPrice != null
                            ? Icons.filter_alt
                            : Icons.filter_alt_outlined,
                      ),
                      tooltip: 'Filter by price',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : results.isEmpty
                ? const Center(child: Text('No listings found'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      return _ListingCard(listing: results[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final Listing listing;

  const _ListingCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ListingDetailScreen(listing: listing),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: listing.photoUrls.isNotEmpty
                  ? Image.network(
                      listing.photoUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Colors.black12,
                        child: Icon(Icons.image_not_supported_outlined),
                      ),
                    )
                  : const ColoredBox(
                      color: Colors.black12,
                      child: Icon(Icons.home_outlined, size: 40),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          listing.listingType == 'rent'
                              ? 'For Rent'
                              : 'For Sale',
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      if (listing.verificationStatus == 'verified') ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified,
                          size: 16,
                          color: Colors.green,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    listing.neighborhood,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${listing.price.toStringAsFixed(0)} ETB${listing.listingType == 'rent' ? '/mo' : ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0E7C5A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
