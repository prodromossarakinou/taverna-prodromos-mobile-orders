import 'package:flutter/material.dart';

import 'package:untitled1/core/config/api_config.dart';
import 'package:untitled1/core/network/waiter_api_client.dart';
import 'package:untitled1/core/theme/app_theme.dart';
import 'package:untitled1/features/orders/domain/models.dart';

class WaiterOrdersScreen extends StatefulWidget {
  const WaiterOrdersScreen({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  State<WaiterOrdersScreen> createState() => _WaiterOrdersScreenState();
}

class _WaiterOrdersScreenState extends State<WaiterOrdersScreen> {
  final WaiterApiClient _api = WaiterApiClient(baseUrl: ApiConfig.baseUrl);
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _ordersScrollController = ScrollController();

  List<ApiOrderSummary> _orders = const [];
  bool _loading = true;
  String? _error;
  bool _isHeaderCollapsed = false;

  @override
  void initState() {
    super.initState();
    _ordersScrollController.addListener(_onOrdersScroll);
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _ordersScrollController
      ..removeListener(_onOrdersScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredOrders();
    final topInset = MediaQuery.of(context).padding.top;
    final headerHeight = (_isHeaderCollapsed ? 72 : 106) + topInset;
    final headerTitle = _isHeaderCollapsed
        ? 'Παραγγελίες(${filtered.length})'
        : 'Δείτε Παραγγελία';

    return Scaffold(
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            height: headerHeight,
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              16,
              topInset + (_isHeaderCollapsed ? 8 : 10),
              16,
              _isHeaderCollapsed ? 8 : 10,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: appHeaderGradient(isDark: isDark),
              ),
            ),
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: 'Πίσω',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(40, 40),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  tooltip: 'Αρχική',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(40, 40),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.home),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    headerTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _isHeaderCollapsed ? 18 : 22,
                      fontWeight:
                          _isHeaderCollapsed ? FontWeight.w600 : FontWeight.w700,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: widget.onToggleTheme,
                  tooltip: isDark ? 'Switch to light theme' : 'Switch to dark theme',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(40, 40),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: palette.surfaceVariant,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Αναζήτηση τραπεζιού ή ID...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close),
                            ),
                      filled: true,
                      fillColor: palette.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: palette.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: palette.outline),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _error!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: palette.onSurfaceMuted),
                                    ),
                                    const SizedBox(height: 12),
                                    FilledButton(
                                      onPressed: _loadOrders,
                                      child: const Text('Ξανά'),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadOrders,
                                child: filtered.isEmpty
                                    ? ListView(
                                        controller: _ordersScrollController,
                                        children: [
                                          const SizedBox(height: 96),
                                          Center(
                                            child: Text(
                                              'Δεν βρέθηκαν παραγγελίες',
                                              style: TextStyle(
                                                color: palette.onSurfaceMuted,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : ListView.separated(
                                        controller: _ordersScrollController,
                                        padding: EdgeInsets.zero,
                                        itemCount: filtered.length,
                                        separatorBuilder: (_, _) =>
                                            const SizedBox(height: 10),
                                        itemBuilder: (context, index) {
                                          final order = filtered[index];
                                          return _OrderSummaryCard(order: order);
                                        },
                                      ),
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onOrdersScroll() {
    if (!_ordersScrollController.hasClients) {
      return;
    }
    final collapsed = _ordersScrollController.offset > 24;
    if (collapsed != _isHeaderCollapsed) {
      setState(() {
        _isHeaderCollapsed = collapsed;
      });
    }
  }

  List<ApiOrderSummary> _filteredOrders() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _orders;
    }

    return _orders.where((order) {
      return order.tableNumber.toLowerCase().contains(query) ||
          order.id.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final orders = await _api.getOrders();
      if (!mounted) {
        return;
      }
      setState(() {
        _orders = orders
            .where(
              (order) =>
                  order.id.isNotEmpty &&
                  order.status.toLowerCase() != 'deleted',
            )
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = 'Σφάλμα φόρτωσης παραγγελιών: ${e.message}';
      });
    }
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.order});

  final ApiOrderSummary order;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor(order.status, palette);
    final groupedItems = _groupItemsByCategory(order.items);

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Τραπέζι ${order.tableNumber}',
                    style: TextStyle(
                      color: palette.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    order.status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (order.isExtra) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'EXTRA',
                      style: TextStyle(
                        color: Color(0xFFF97316),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'ID: ${order.id}',
              style: TextStyle(color: palette.onSurfaceMuted, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'Σερβιτόρος: ${order.waiterName.isEmpty ? '-' : order.waiterName} • Προϊόντα: ${order.itemsCount}',
              style: TextStyle(color: palette.onSurfaceMuted, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Ώρα: ${_formatTimestamp(order.timestamp)}',
              style: TextStyle(color: palette.onSurfaceMuted, fontSize: 13),
            ),
            const SizedBox(height: 8),
            if (order.items.isEmpty)
              Text(
                'Χωρίς items',
                style: TextStyle(color: palette.onSurfaceMuted, fontSize: 12),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: groupedItems.entries.map((entry) {
                  final category = entry.key;
                  final items = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style: TextStyle(
                            color: palette.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: items
                              .map(
                                (item) {
                                  final visual = _itemVisualState(item, isDark);
                                  final itemColor = visual.color;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: itemColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: itemColor),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: itemColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${item.name} x${item.quantity}',
                                          style: TextStyle(
                                            color: itemColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (visual.tag != null) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            visual.tag!,
                                            style: TextStyle(
                                              color: itemColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  static Map<String, List<ApiOrderItemSummary>> _groupItemsByCategory(
    List<ApiOrderItemSummary> items,
  ) {
    final grouped = <String, List<ApiOrderItemSummary>>{};
    for (final item in items.where((i) => i.name.isNotEmpty)) {
      grouped.putIfAbsent(item.category, () => <ApiOrderItemSummary>[]).add(item);
    }
    return grouped;
  }

  static Color _statusColor(String status, AppPalette palette) {
    final normalized = status.toLowerCase();
    if (normalized == 'pending') {
      return const Color(0xFF374151);
    }
    if (normalized == 'ready') {
      return AppColors.primary;
    }
    if (normalized == 'delivered' || normalized == 'completed' || normalized == 'closed') {
      return palette.success;
    }
    if (normalized == 'cancelled') {
      return palette.error;
    }

    switch (status) {
      default:
        return const Color(0xFF374151);
    }
  }

  static ({Color color, String? tag}) _itemVisualState(
    ApiOrderItemSummary item,
    bool isDark,
  ) {
    final blue = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
    final green = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
    final gray = isDark ? const Color(0xFF4B5563) : const Color(0xFF374151);

    if (item.units.isNotEmpty) {
      if (item.units.length == 1) {
        final normalized = item.itemStatus.toLowerCase();
        if (normalized == 'delivered') {
          return (color: green, tag: null);
        }
        if (normalized == 'ready') {
          return (color: blue, tag: null);
        }
        return (color: gray, tag: null);
      }

      final unitStatuses = item.units.map((u) => u.status.toLowerCase());
      final totalUnits = item.units.length;
      final readyCount = unitStatuses.where((s) => s == 'ready').length;
      final deliveredCount = unitStatuses.where((s) => s == 'delivered').length;
      final allPending = unitStatuses.every((s) => s == 'pending');

      if (deliveredCount == totalUnits && totalUnits > 0) {
        return (color: green, tag: null);
      }
      if (readyCount > 0) {
        return (color: blue, tag: '($readyCount/$totalUnits)');
      }
      if (allPending) {
        return (color: gray, tag: null);
      }
      return (color: gray, tag: null);
    }

    final normalized = item.itemStatus.toLowerCase();
    if (normalized == 'delivered') {
      return (color: green, tag: null);
    }
    if (normalized == 'ready') {
      return (color: blue, tag: null);
    }
    return (color: gray, tag: null);
  }

  static String _formatTimestamp(int raw) {
    final millis = raw > 1000000000000 ? raw : raw * 1000;
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    final mo = date.month.toString().padLeft(2, '0');
    return '$dd/$mo ${hh}:$mm';
  }
}
