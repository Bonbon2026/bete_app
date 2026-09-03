import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/listing.dart';

class ListingDetailScreen extends StatefulWidget {
  final Listing listing;

  const ListingDetailScreen({super.key, required this.listing});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final PageController _photoController = PageController();
  int _currentPhoto = 0;
  String? _ownerPhone;
  bool _loadingOwner = true;

  @override
  void initState() {
    super.initState();
    _loadOwnerContact();
  }

  Future<void> _loadOwnerContact() async {
    try {
      final supabase = Supabase.instance.client;
      final listingRow = await supabase
          .from('listings')
          .select('owner_id')
          .eq('id', widget.listing.id)
          .single();

      final ownerId = listingRow['owner_id'] as String;

      final profile = await supabase
          .from('profiles')
          .select('phone')
          .eq('id', ownerId)
          .maybeSingle();

      setState(() {
        _ownerPhone = profile?['phone'] as String?;
        _loadingOwner = false;
      });
    } catch (e) {
      setState(() => _loadingOwner = false);
    }
  }

  Future<void> _callOwner() async {
    if (_ownerPhone == null) return;
    final uri = Uri(scheme: 'tel', path: _ownerPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showReportDialog() {
    final reasonController = TextEditingController();
    String selectedReason = 'Suspicious / scam';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Report this listing'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButton<String>(
                value: selectedReason,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: 'Suspicious / scam',
                    child: Text('Suspicious / scam'),
                  ),
                  DropdownMenuItem(
                    value: 'Fake photos',
                    child: Text('Fake photos'),
                  ),
                  DropdownMenuItem(
                    value: 'Already rented/sold',
                    child: Text('Already rented/sold'),
                  ),
                  DropdownMenuItem(
                    value: 'Wrong information',
                    child: Text('Wrong information'),
                  ),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) =>
                    setDialogState(() => selectedReason = value!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Additional details (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  final supabase = Supabase.instance.client;
                  await supabase.from('reports').insert({
                    'listing_id': widget.listing.id,
                    'reporter_id': supabase.auth.currentUser!.id,
                    'reason': selectedReason,
                    'details': reasonController.text.trim().isEmpty
                        ? null
                        : reasonController.text.trim(),
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Report submitted. Thank you.'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to submit report: $e')),
                    );
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Report this listing',
            onPressed: _showReportDialog,
          ),
        ],
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 280,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _photoController,
                  itemCount: listing.photoUrls.isEmpty
                      ? 1
                      : listing.photoUrls.length,
                  onPageChanged: (i) => setState(() => _currentPhoto = i),
                  itemBuilder: (context, index) {
                    if (listing.photoUrls.isEmpty) {
                      return const ColoredBox(
                        color: Colors.black12,
                        child: Icon(Icons.home_outlined, size: 64),
                      );
                    }
                    return Image.network(
                      listing.photoUrls[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Colors.black12,
                        child: Icon(Icons.image_not_supported_outlined),
                      ),
                    );
                  },
                ),
                if (listing.photoUrls.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        listing.photoUrls.length,
                        (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == _currentPhoto
                                ? Colors.white
                                : Colors.white38,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(
                      label: Text(
                        listing.listingType == 'rent' ? 'For Rent' : 'For Sale',
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (listing.verificationStatus == 'verified' &&
                        listing.lastVerifiedAt != null)
                      Chip(
                        avatar: const Icon(
                          Icons.verified,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Verified ${_formatDate(listing.lastVerifiedAt!)}',
                        ),
                        backgroundColor: const Color(0xFF0E7C5A),
                        labelStyle: const TextStyle(color: Colors.white),
                      )
                    else
                      const Chip(label: Text('Unverified')),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  listing.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        listing.neighborhood,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
                if (listing.address != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    listing.address!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  '${listing.price.toStringAsFixed(0)} ETB${listing.listingType == 'rent' ? '/mo' : ''}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0E7C5A),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(listing.description, style: const TextStyle(height: 1.4)),
                const SizedBox(height: 24),
                const Text(
                  'Contact',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                if (_ownerPhone != null)
                  InkWell(
                    onTap: _callOwner,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 18,
                          color: Color(0xFF0E7C5A),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _ownerPhone!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF0E7C5A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (!_loadingOwner)
                  Text(
                    'Owner contact info not available yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
