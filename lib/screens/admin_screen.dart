import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _pendingListings = [];
  List<Map<String, dynamic>> _pendingReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      final listings = await supabase
          .from('listings')
          .select('*, media(id, url)')
          .eq('verification_status', 'unverified')
          .order('created_at');

      final reports = await supabase
          .from('reports')
          .select('*, listings(title)')
          .eq('status', 'pending')
          .order('created_at');

      final listingsList = List<Map<String, dynamic>>.from(listings);

      for (final listing in listingsList) {
        final profile = await supabase
            .from('profiles')
            .select('phone')
            .eq('id', listing['owner_id'] as String)
            .maybeSingle();
        listing['owner_phone'] = profile?['phone'] as String?;
      }

      listingsList.sort((a, b) {
        final aReady = _isReadyForReview(a) ? 0 : 1;
        final bReady = _isReadyForReview(b) ? 0 : 1;
        return aReady.compareTo(bReady);
      });

      setState(() {
        _pendingListings = listingsList;
        _pendingReports = List<Map<String, dynamic>>.from(reports);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to load: $e')));
      }
    }
  }

  bool _isReadyForReview(Map<String, dynamic> listing) {
    final description = listing['description'] as String? ?? '';
    final neighborhood = listing['neighborhood'] as String? ?? '';
    final mediaList = listing['media'] as List? ?? [];
    final ownerPhone = listing['owner_phone'] as String?;
    return description.trim().length >= 20 &&
        neighborhood.trim().isNotEmpty &&
        mediaList.length >= 3 &&
        ownerPhone != null &&
        ownerPhone.isNotEmpty;
  }

  List<String> _incompleteReasons(Map<String, dynamic> listing) {
    final reasons = <String>[];
    final description = listing['description'] as String? ?? '';
    final neighborhood = listing['neighborhood'] as String? ?? '';
    final mediaList = listing['media'] as List? ?? [];
    final ownerPhone = listing['owner_phone'] as String?;

    if (description.trim().length < 20) {
      reasons.add('Description is too short (needs 20+ characters)');
    }
    if (neighborhood.trim().isEmpty) {
      reasons.add('Neighborhood is missing');
    }
    if (mediaList.length < 3) {
      reasons.add('Only ${mediaList.length} photo(s) — needs at least 3');
    }
    if (ownerPhone == null || ownerPhone.isEmpty) {
      reasons.add('Owner has no phone number on file');
    }
    return reasons;
  }

  Future<void> _approveListing(String listingId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('listings')
          .update({
            'verification_status': 'verified',
            'last_verified_at': DateTime.now().toIso8601String(),
          })
          .eq('id', listingId);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Listing verified')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _resolveReport(String reportId, String status) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('reports')
          .update({'status': status})
          .eq('id', reportId);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Listings (${_pendingListings.length})'),
            Tab(text: 'Reports (${_pendingReports.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildListingsTab(), _buildReportsTab()],
            ),
    );
  }

  Widget _buildListingsTab() {
    if (_pendingListings.isEmpty) {
      return const Center(child: Text('No listings awaiting verification'));
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _pendingListings.length,
        itemBuilder: (context, index) {
          final listing = _pendingListings[index];
          final ready = _isReadyForReview(listing);
          final photoUrls = (listing['media'] as List)
              .map((m) => m['url'] as String)
              .toList();

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ExpansionTile(
              title: Row(
                children: [
                  Expanded(child: Text(listing['title'] as String)),
                  GestureDetector(
                    onTap: ready
                        ? null
                        : () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Why this is incomplete'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _incompleteReasons(listing)
                                      .map(
                                        (r) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 6,
                                          ),
                                          child: Text('• $r'),
                                        ),
                                      )
                                      .toList(),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: ready ? Colors.green[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ready ? Colors.green : Colors.orange,
                        ),
                      ),
                      child: Text(
                        ready ? 'Ready' : 'Incomplete',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: ready ? Colors.green[800] : Colors.orange[800],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                '${listing['neighborhood']} • ${(listing['price'] as num).toStringAsFixed(0)} ETB',
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (photoUrls.isNotEmpty)
                        SizedBox(
                          height: 90,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: photoUrls.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 6),
                            itemBuilder: (context, i) => ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                photoUrls[i],
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Text(
                        listing['description'] as String? ?? '',
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: () =>
                              _approveListing(listing['id'] as String),
                          child: const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportsTab() {
    if (_pendingReports.isEmpty) {
      return const Center(child: Text('No pending reports'));
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _pendingReports.length,
        itemBuilder: (context, index) {
          final report = _pendingReports[index];
          final listingTitle =
              report['listings']?['title'] as String? ?? 'Unknown listing';
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listingTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('Reason: ${report['reason']}'),
                  if (report['details'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      report['details'] as String,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () =>
                            _resolveReport(report['id'] as String, 'dismissed'),
                        child: const Text('Dismiss'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () =>
                            _resolveReport(report['id'] as String, 'reviewed'),
                        child: const Text('Mark Reviewed'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
