import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../providers/vehicle_log_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/scan_action_card.dart';
import '../widgets/vehicle_log_card.dart';
import 'camera_scanner_screen.dart';
import 'splash_screen.dart';

/// Screen 1: Dashboard — Live log of vehicles, search, and checkout actions.
class DashboardScreen extends StatefulWidget {
  final String apiKey;

  const DashboardScreen({super.key, required this.apiKey});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  static const _storage = FlutterSecureStorage();
  static const _apiKeyStorageKey = 'gemini_api_key';

  final _searchController = TextEditingController();
  late TabController _tabController;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleLogProvider>().loadAllLogs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _openScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CameraScannerScreen(apiKey: widget.apiKey),
      ),
    ).then((_) {
      // Reload logs after returning from scanner
      context.read<VehicleLogProvider>().loadAllLogs();
    });
  }

  Future<void> _confirmCheckOut(BuildContext ctx, String id, String plate) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirm Exit', style: AppTheme.headlineSm),
        content: Text(
          'Mark $plate as exited?',
          style: AppTheme.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text('Cancel',
                style: AppTheme.bodyMd.copyWith(color: AppTheme.outline)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('EXIT NOW'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final success =
          await context.read<VehicleLogProvider>().checkOutVehicle(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$plate marked as Exited'),
            backgroundColor: AppTheme.surfaceContainerHighest,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext ctx, String id, String plate) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Log', style: AppTheme.headlineSm),
        content: Text(
          'Permanently delete the log for $plate?',
          style: AppTheme.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text('Cancel',
                style: AppTheme.bodyMd.copyWith(color: AppTheme.outline)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text('Delete',
                style: AppTheme.bodyMd.copyWith(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<VehicleLogProvider>().deleteLog(id);
    }
  }

  Future<void> _resetApiKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reset API Key', style: AppTheme.headlineSm),
        content: Text(
          'This will remove your stored Gemini API key. '
          'You will need to enter it again on the next launch.',
          style: AppTheme.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: AppTheme.bodyMd.copyWith(color: AppTheme.outline)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Reset',
                style: AppTheme.bodyMd.copyWith(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _storage.delete(key: _apiKeyStorageKey);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppTheme.primaryContainer.withValues(alpha: 0.4)),
            ),
            child: const Icon(
              Icons.local_parking_rounded,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ParkSnap', style: AppTheme.headlineSm),
            Text(
              'GATE REGISTER',
              style: AppTheme.labelSm.copyWith(
                color: AppTheme.outline,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppTheme.onSurface),
            color: AppTheme.surfaceContainerHigh,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) {
              if (val == 'reset_key') _resetApiKey();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'reset_key',
                child: Row(
                  children: [
                    const Icon(Icons.vpn_key_outlined,
                        color: AppTheme.secondary, size: 18),
                    const SizedBox(width: 10),
                    Text('Reset API Key', style: AppTheme.bodyMd),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<VehicleLogProvider>(
        builder: (ctx, provider, _) {
          return RefreshIndicator(
            color: AppTheme.primary,
            backgroundColor: AppTheme.surfaceContainer,
            onRefresh: () => provider.loadAllLogs(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero scan card
                        ScanActionCard(
                          onTap: _openScanner,
                          insideCount: provider.insideCount,
                        ),
                        const SizedBox(height: 16),

                        // Search bar
                        TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            provider.search(val);
                            setState(() => _isSearching = val.isNotEmpty);
                          },
                          style: AppTheme.labelLg
                              .copyWith(color: AppTheme.onSurface),
                          decoration: InputDecoration(
                            hintText: 'Search license plate...',
                            prefixIcon: const Icon(Icons.search_rounded,
                                color: AppTheme.outline, size: 20),
                            suffixIcon: _isSearching
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded,
                                        color: AppTheme.outline, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      provider.clearSearch();
                                      setState(() => _isSearching = false);
                                    },
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Tabs
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.primary,
                      unselectedLabelColor: AppTheme.onSurfaceVariant,
                      labelStyle: AppTheme.labelLg,
                      unselectedLabelStyle: AppTheme.labelLg,
                      indicatorColor: AppTheme.primary,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: AppTheme.outlineVariant,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.radio_button_checked_rounded,
                                  size: 14),
                              const SizedBox(width: 6),
                              Text('INSIDE (${provider.insideCount})'),
                            ],
                          ),
                        ),
                        const Tab(text: 'ALL LOGS'),
                      ],
                    ),
                  ),
                ),

                // List content
                if (provider.isLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                  )
                else if (_isSearching)
                  _buildLogList(
                    provider.searchResults,
                    provider,
                    emptyMessage: 'No results for "${provider.searchQuery}"',
                  )
                else
                  SliverFillRemaining(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Inside tab
                        _buildListView(
                          provider.insideLogs,
                          provider,
                          emptyMessage: 'No vehicles inside right now.\nTap SCAN to log the first entry.',
                        ),
                        // All logs tab
                        _buildListView(
                          provider.allLogs,
                          provider,
                          emptyMessage: 'No logs yet.\nScan your first vehicle to begin.',
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openScanner,
        backgroundColor: AppTheme.primaryContainer,
        foregroundColor: AppTheme.onPrimary,
        icon: const Icon(Icons.camera_alt_rounded),
        label: Text('SCAN', style: AppTheme.labelLg.copyWith(color: AppTheme.onPrimary)),
      ),
    );
  }

  Widget _buildListView(
    List logs,
    VehicleLogProvider provider, {
    required String emptyMessage,
  }) {
    if (logs.isEmpty) {
      return _EmptyState(message: emptyMessage, onScan: _openScanner);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: logs.length,
      itemBuilder: (ctx, i) {
        final log = logs[i];
        return Dismissible(
          key: Key(log.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppTheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            await _confirmDelete(ctx, log.id, log.licensePlate);
            return false; // We handle deletion ourselves
          },
          child: VehicleLogCard(
            log: log,
            onCheckOut: log.status == 'Inside'
                ? () => _confirmCheckOut(ctx, log.id, log.licensePlate)
                : null,
            onDelete: () => _confirmDelete(ctx, log.id, log.licensePlate),
          ),
        );
      },
    );
  }

  SliverList _buildLogList(
    List logs,
    VehicleLogProvider provider, {
    required String emptyMessage,
  }) {
    if (logs.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          _EmptyState(message: emptyMessage, onScan: _openScanner),
        ]),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) {
          final log = logs[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: VehicleLogCard(
              log: log,
              onCheckOut: log.status == 'Inside'
                  ? () => _confirmCheckOut(ctx, log.id, log.licensePlate)
                  : null,
            ),
          );
        },
        childCount: logs.length,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final VoidCallback onScan;

  const _EmptyState({required this.message, required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.no_photography_outlined,
              color: AppTheme.outline,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTheme.bodyMd,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 160,
              child: ElevatedButton.icon(
                onPressed: onScan,
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                label: const Text('SCAN'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.background,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
