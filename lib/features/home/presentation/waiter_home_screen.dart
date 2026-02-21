import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:untitled1/core/config/api_config.dart';
import 'package:untitled1/core/network/waiter_api_client.dart';
import 'package:untitled1/core/theme/app_theme.dart';
import 'package:untitled1/features/orders/domain/models.dart';
import 'package:untitled1/features/orders/presentation/waiter_orders_screen.dart';
import 'package:untitled1/features/waiter_view/presentation/waiter_view_screen.dart';

class WaiterHomeScreen extends StatelessWidget {
  const WaiterHomeScreen({
    super.key,
    required this.onToggleTheme,
  });

  static final WaiterApiClient _api = WaiterApiClient(baseUrl: ApiConfig.baseUrl);

  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      body: Column(
        children: [
          _HomeHeader(
            isDark: Theme.of(context).brightness == Brightness.dark,
            onToggleTheme: onToggleTheme,
          ),
          Expanded(
            child: Container(
              color: palette.surfaceVariant,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ActionCard(
                    icon: Icons.add_circle,
                    iconColor: AppColors.primary,
                    title: 'Νέα Παραγγελία',
                    subtitle: 'Ξεκινήστε μια νέα παραγγελία',
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      final tableNumber = await _showTableNumberDialog(context);
                      if (!context.mounted || tableNumber == null) {
                        return;
                      }

                      var mode = WaiterMode.newOrder;
                      final hasExisting = await _hasExistingOrder(tableNumber);
                      if (!context.mounted) {
                        return;
                      }
                      if (hasExisting) {
                        final asExtra = await _showExtraDecisionDialog(context);
                        if (!context.mounted || asExtra == null) {
                          return;
                        }
                        mode = asExtra ? WaiterMode.addExtra : WaiterMode.newOrder;
                      }

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WaiterViewScreen(
                            mode: mode,
                            initialTable: tableNumber,
                            onToggleTheme: onToggleTheme,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _ActionCard(
                    icon: Icons.add_box,
                    iconColor: AppColors.cold,
                    title: 'Προσθήκη Έξτρα',
                    subtitle: 'Προσθέστε σε υπάρχουσα παραγγελία',
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      final selectedTable =
                          await _showTableSelectorBottomSheet(context);
                      if (!context.mounted || selectedTable == null) {
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WaiterViewScreen(
                            mode: WaiterMode.addExtra,
                            initialTable: selectedTable,
                            onToggleTheme: onToggleTheme,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _ActionCard(
                    icon: Icons.search,
                    iconColor: AppColors.primary,
                    title: 'Δείτε Παραγγελία',
                    subtitle: 'Αναζητήστε υπάρχουσες παραγγελίες',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WaiterOrdersScreen(
                            onToggleTheme: onToggleTheme,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showTableSelectorBottomSheet(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final maxHeight = MediaQuery.of(context).size.height * 0.7;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Επιλογή Τραπεζιού',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<ApiOrderSummary>>(
                      future: _api.getOrders(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (snapshot.hasError) {
                          return Text(
                            'Σφάλμα φόρτωσης τραπεζιών',
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          );
                        }

                        final tables = (snapshot.data ?? const <ApiOrderSummary>[])
                            .where((order) => order.status != 'closed')
                            .map((order) => order.tableNumber)
                            .where((table) => table.trim().isNotEmpty)
                            .toSet()
                            .toList()
                          ..sort((a, b) {
                            final aInt = int.tryParse(a);
                            final bInt = int.tryParse(b);
                            if (aInt != null && bInt != null) {
                              return aInt.compareTo(bInt);
                            }
                            return a.compareTo(b);
                          });

                        if (tables.isEmpty) {
                          return const Text('Δεν υπάρχουν ανοιχτά τραπέζια.');
                        }

                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tables.map((table) {
                            return FilledButton.tonal(
                              onPressed: () => Navigator.of(context).pop(table),
                              child: Text('Τραπέζι $table'),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<String?> _showTableNumberDialog(BuildContext context) async {
    var value = '';
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Αριθμός Τραπεζιού'),
          content: TextFormField(
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => value = v,
            decoration: const InputDecoration(
              hintText: 'π.χ. 12',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ακύρωση'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(value.trim()),
              child: const Text('Συνέχεια'),
            ),
          ],
        );
      },
    ).then((result) {
      final trimmed = result?.trim() ?? '';
      if (trimmed.isEmpty) {
        return null;
      }
      return trimmed;
    });
  }

  Future<bool> _hasExistingOrder(String tableNumber) async {
    try {
      final orders = await _api.getOrders();
      return orders.any(
        (order) =>
            order.tableNumber == tableNumber &&
            order.status != 'closed' &&
            order.status != 'cancelled',
      );
    } on ApiException {
      return false;
    }
  }

  Future<bool?> _showExtraDecisionDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Υπάρχει ήδη παραγγελία'),
          content: const Text(
            'Υπάρχει ήδη παραγγελία για αυτό το τραπέζι. Θέλετε να προστεθεί ως extra;',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Εκκίνηση νέας'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Extra'),
            ),
          ],
        );
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.isDark, required this.onToggleTheme});

  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      height: 104 + top,
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, top + 10, 16, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: appHeaderGradient(isDark: isDark),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Επιλέξτε Ενέργεια',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
          IconButton.filledTonal(
            onPressed: onToggleTheme,
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
    );
  }
}

class _ActionCard extends StatefulWidget {
  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final opacity = widget.enabled ? 1.0 : 0.5;

    return Opacity(
      opacity: opacity,
      child: Material(
        elevation: _pressed && widget.enabled ? 8 : 2,
        borderRadius: BorderRadius.circular(12),
        color: palette.surface,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.enabled ? widget.onTap : null,
          onHighlightChanged: widget.enabled
              ? (value) {
                  setState(() {
                    _pressed = value;
                  });
                }
              : null,
          splashColor: AppColors.primary.withValues(alpha: 0.12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(widget.icon, size: 48, color: widget.iconColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: widget.enabled ? palette.onSurface : AppColors.muted,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          color: widget.enabled
                              ? palette.onSurfaceMuted
                              : AppColors.muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
