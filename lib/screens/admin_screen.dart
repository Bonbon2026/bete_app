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
          .select()
          .eq('verification_status', 'unverified')
          .order('created_at');

      final reports = await supabase
          .from('reports')
          .select('*, listings(title)')
          .eq('status', 'pending')
          .order('created_at');

      setState(() {
        _pendingListings = List<Map<String, dynamic>>.from(listings);
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
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(listing['title'] as String),
              subtitle: Text(
                '${listing['neighborhood']} • ${(listing['price'] as num).toStringAsFixed(0)} ETB',
              ),
              trailing: FilledButton(
                onPressed: () => _approveListing(listing['id'] as String),
                child: const Text('Approve'),
              ),
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
