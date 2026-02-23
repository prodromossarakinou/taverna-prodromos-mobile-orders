import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import 'package:untitled1/core/config/api_config.dart';
import 'package:untitled1/core/network/waiter_api_client.dart';
import 'package:untitled1/core/theme/app_theme.dart';
import 'package:untitled1/features/orders/domain/models.dart';

class WaiterViewScreen extends StatefulWidget {
  const WaiterViewScreen({
    super.key,
    required this.mode,
    required this.onToggleTheme,
    this.initialTable,
  });

  final WaiterMode mode;
  final VoidCallback onToggleTheme;
  final String? initialTable;

  @override
  State<WaiterViewScreen> createState() => _WaiterViewScreenState();
}

class _WaiterViewScreenState extends State<WaiterViewScreen> {
  final WaiterApiClient _api = WaiterApiClient(baseUrl: ApiConfig.baseUrl);
  final TextEditingController _tableController = TextEditingController();
  final TextEditingController _waiterController = TextEditingController();
  final TextEditingController _menuSearchController = TextEditingController();
  final ScrollController _orderListController = ScrollController();
  final ScrollController _menuGridScrollController = ScrollController();

  String? _selectedCategory;
  List<MenuProduct> _menuProducts = const [];
  final List<OrderLine> _orderLines = [];
  final Set<String> _removingIds = <String>{};
  bool _isLoadingMenu = true;
  bool _isRefreshingMenu = false;
  String? _menuError;
  String? _parentOrderId;
  Timer? _menuRefreshTimer;
  bool _isHeaderCollapsed = false;
  bool _repeatOrderFilterEnabled = false;
  Set<String> _repeatOrderProductIds = <String>{};
  Set<String> _repeatOrderProductNames = <String>{};

  @override
  void initState() {
    super.initState();
    if (widget.initialTable != null) {
      _tableController.text = widget.initialTable!;
    }
    _repeatOrderFilterEnabled = widget.mode == WaiterMode.addExtra;
    _menuGridScrollController.addListener(_onMenuScroll);
    _loadInitialData();
    _menuRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _refreshMenu(showLoading: false, showErrorState: false);
    });
  }

  @override
  void dispose() {
    _tableController.dispose();
    _waiterController.dispose();
    _menuSearchController.dispose();
    _orderListController.dispose();
    _menuGridScrollController
      ..removeListener(_onMenuScroll)
      ..dispose();
    _menuRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panelHeight = MediaQuery.of(context).size.height * 0.40;
    final hasItems = _orderLines.isNotEmpty;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              _buildWaiterHeader(),
              _buildCategoryTabs(),
              Expanded(
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.only(bottom: hasItems ? panelHeight : 0),
                  child: _buildMenuGrid(),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 250),
              curve: const Cubic(0.4, 0.0, 0.2, 1.0),
              offset: hasItems ? Offset.zero : const Offset(0, 1),
              child: IgnorePointer(
                ignoring: !hasItems,
                child: _buildOrderSummaryPanel(panelHeight),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaiterHeader() {
    final top = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final table = _tableController.text.trim();
    final compactTitle = table.isEmpty ? 'Λήψη Παραγγελίας' : 'Τραπέζι $table';
    final isExtraMode = widget.mode == WaiterMode.addExtra;
    final expandedTitle = widget.mode == WaiterMode.newOrder
        ? 'Λήψη Παραγγελίας'
        : 'Λήψη Παραγγελίας (Έξτρα)';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      padding: EdgeInsets.fromLTRB(
        16,
        top + (_isHeaderCollapsed ? 8 : 12),
        16,
        12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isExtraMode
              ? (isDark
                    ? const [Color(0xFFEA580C), Color(0xFF9A3412)]
                    : const [Color(0xFFF97316), Color(0xFFEA580C)])
              : appHeaderGradient(isDark: isDark),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _isHeaderCollapsed ? compactTitle : expandedTitle,
                  style: TextStyle(
                    fontSize: _isHeaderCollapsed ? 18 : 22,
                    fontWeight: _isHeaderCollapsed
                        ? FontWeight.w600
                        : FontWeight.w700,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: widget.onToggleTheme,
                tooltip: isDark
                    ? 'Switch to light theme'
                    : 'Switch to dark theme',
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
          AnimatedCrossFade(
            firstChild: Column(
              children: [
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: _HeaderInput(
                        label: 'Τραπέζι',
                        controller: _tableController,
                        hint: 'π.χ. 12',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HeaderInput(
                        label: 'Σερβιτόρος',
                        controller: _waiterController,
                        hint: 'Όνομα',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _isHeaderCollapsed
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final palette = AppPalette.of(context);
    final isExtraMode = widget.mode == WaiterMode.addExtra;
    final categories = _menuCategories;

    Widget buildRepeatChip() {
      return Padding(
        padding: const EdgeInsets.only(left: 8, right: 8),
        child: Semantics(
          button: true,
          selected: _repeatOrderFilterEnabled,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _repeatOrderFilterEnabled = !_repeatOrderFilterEnabled;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: _repeatOrderFilterEnabled
                    ? AppColors.hot.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: _repeatOrderFilterEnabled
                    ? Border.all(
                        color: AppColors.hot.withValues(alpha: 0.80),
                        width: 1.4,
                      )
                    : Border.all(color: Colors.transparent),
              ),
              child: Center(
                child: Text(
                  'ΞΑΝΑ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _repeatOrderFilterEnabled
                        ? palette.onSurface
                        : palette.onSurfaceMuted,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(bottom: BorderSide(color: palette.outline, width: 1)),
      ),
      child: Row(
        children: [
          if (isExtraMode) buildRepeatChip(),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(
                left: isExtraMode ? 0 : 8,
                right: 8,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isActive = category == _selectedCategory;
                final categoryColor = _categoryColor(category);
                return Semantics(
                  button: true,
                  selected: isActive,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? categoryColor.withValues(alpha: 0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isActive
                            ? Border.all(
                                color: categoryColor.withValues(alpha: 0.80),
                                width: 1.4,
                              )
                            : Border.all(color: Colors.transparent),
                      ),
                      child: Center(
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isActive
                                ? palette.onSurface
                                : palette.onSurfaceMuted,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    final palette = AppPalette.of(context);
    final isExtraMode = widget.mode == WaiterMode.addExtra;
    final categoryItems = _menuProducts
        .where(
          (item) =>
              _selectedCategory == null || item.category == _selectedCategory,
        )
        .where(_matchesMenuSearch)
        .where(
          (item) =>
              !isExtraMode ||
              !_repeatOrderFilterEnabled ||
              _matchesRepeatOrderProducts(item),
        )
        .toList();

    return Container(
      color: palette.surfaceVariant,
      padding: const EdgeInsets.all(16),
      child: _isLoadingMenu
          ? const Center(child: CircularProgressIndicator())
          : _menuError != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _menuError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: palette.onSurfaceMuted),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _loadInitialData,
                    child: const Text('Ξανά'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  height: 40,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    border: Border.all(color: palette.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        size: 16,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _menuSearchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Αναζήτηση προϊόντος ή κατηγορίας...',
                            border: InputBorder.none,
                            isDense: true,
                            hintStyle: TextStyle(color: palette.onSurfaceMuted),
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            color: palette.onSurface,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Ανανέωση προϊόντων',
                        onPressed: _isRefreshingMenu
                            ? null
                            : () => _refreshMenu(
                                showLoading: false,
                                showErrorState: true,
                              ),
                        icon: _isRefreshingMenu
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.refresh,
                                size: 16,
                                color: AppColors.gray500,
                              ),
                      ),
                      if (_menuSearchController.text.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            _menuSearchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: AppColors.gray500,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: categoryItems.isEmpty
                      ? (isExtraMode &&
                                (_repeatOrderFilterEnabled ||
                                    _menuSearchController.text.trim().isNotEmpty)
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Δεν υπάρχουν προϊόντα σε αυτή την κατηγορία με τα ενεργά φίλτρα.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: palette.onSurfaceMuted,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          _repeatOrderFilterEnabled = false;
                                          _menuSearchController.clear();
                                        });
                                      },
                                      child: const Text('Καθαρισμός φίλτρων'),
                                    ),
                                  ],
                                ),
                              )
                            : const _EmptyCategoryState())
                      : GridView.builder(
                          controller: _menuGridScrollController,
                          padding: EdgeInsets.zero,
                          itemCount: categoryItems.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 2.4,
                              ),
                          itemBuilder: (context, index) {
                            final item = categoryItems[index];
                            return _MenuItemCard(
                              item: item,
                              onTap: item.active ? () => _addProduct(item) : null,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildOrderSummaryPanel(double panelHeight) {
    final palette = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: panelHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: isDark ? 0.86 : 0.94),
        border: Border(
          top: BorderSide(
            color: palette.outline.withValues(alpha: isDark ? 0.70 : 0.80),
            width: 4,
          ),
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        spacing: 5.0,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Expanded(
                  child: _orderLines.isEmpty
                      ? Center(
                          child: Text(
                            'Η παραγγελία είναι κενή',
                            style: TextStyle(
                              fontSize: 14,
                              color: palette.onSurfaceMuted,
                              height: 1.4,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _orderListController,
                          itemCount: _orderLines.length,
                          itemBuilder: (context, index) {
                            final line = _orderLines[index];
                            final isRemoving = _removingIds.contains(
                              line.product.id,
                            );
                            return AnimatedOpacity(
                              duration: const Duration(milliseconds: 150),
                              opacity: isRemoving ? 0 : 1,
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 150),
                                curve: Curves.easeOut,
                                alignment: Alignment.topCenter,
                                child: isRemoving
                                    ? const SizedBox.shrink()
                                    : _OrderLineCard(
                                        line: line,
                                        onIncrement: () => _incrementLine(line),
                                        onDecrement: () => _decrementLine(line),
                                        onDelete: () => _removeLine(line),
                                        onNote: () => _openNoteDialog(line),
                                      ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          VerticalDivider(
            width: 1,
            color: palette.outline.withValues(alpha: 0.80),
          ),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 4,
                  child: _ActionPanelButton(
                    icon: Icons.send,
                    color: palette.success,
                    onTap: _submitOrder,
                  ),
                ),
                const SizedBox(height: 20,),
                Expanded(
                  flex: 3,
                  child: _ActionPanelButton(
                    icon: Icons.delete_forever,
                    color: palette.error,
                    onTap: _clearOrder,
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _matchesMenuSearch(MenuProduct product) {
    final query = _menuSearchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }
    final name = product.name.toLowerCase();
    final category = product.category.toLowerCase();
    return name.contains(query) || category.contains(query);
  }

  bool _matchesRepeatOrderProducts(MenuProduct product) {
    if (_repeatOrderProductIds.contains(product.id)) {
      return true;
    }
    return _repeatOrderProductNames.contains(product.name.toLowerCase());
  }

  void _addProduct(MenuProduct product) {
    if (!product.active) {
      return;
    }
    HapticFeedback.mediumImpact();

    final index = _orderLines.indexWhere(
      (line) => line.product.id == product.id,
    );
    if (index >= 0) {
      setState(() {
        _orderLines[index].quantity += 1;
      });
    } else {
      setState(() {
        _orderLines.add(OrderLine(product: product, quantity: 1));
      });
      _announce('${product.name}, προστέθηκε');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_orderListController.hasClients) {
        _orderListController.animateTo(
          _orderListController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _incrementLine(OrderLine line) {
    HapticFeedback.lightImpact();
    setState(() {
      line.quantity += 1;
    });
  }

  void _decrementLine(OrderLine line) {
    HapticFeedback.lightImpact();
    if (line.quantity > 1) {
      setState(() {
        line.quantity -= 1;
      });
      return;
    }
    _removeLine(line);
  }

  Future<void> _removeLine(OrderLine line) async {
    if (_removingIds.contains(line.product.id)) {
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _removingIds.add(line.product.id);
    });

    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) {
      return;
    }

    setState(() {
      _orderLines.removeWhere(
        (element) => element.product.id == line.product.id,
      );
      _removingIds.remove(line.product.id);
    });

    _announce('Αφαιρέθηκε ${line.product.name}');
  }

  Future<void> _openNoteDialog(OrderLine line) async {
    var draftNote = line.note ?? '';

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Σημείωση για το προϊόν'),
          content: TextFormField(
            initialValue: draftNote,
            maxLines: 3,
            onChanged: (value) => draftNote = value,
            decoration: const InputDecoration(hintText: 'Προσθέστε σημείωση'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ακύρωση'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(draftNote.trim()),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      line.note = result.isEmpty ? null : result;
    });
  }

  Future<void> _submitOrder() async {
    final palette = AppPalette.of(context);

    if (_tableController.text.trim().isEmpty) {
      _showSnack('Παρακαλώ εισάγετε αριθμό τραπεζιού', palette.error);
      return;
    }

    if (_orderLines.isEmpty) {
      _showSnack('Προσθέστε προϊόντα στην παραγγελία', palette.error);
      return;
    }

    final confirmed = await _confirmDialog(
      title: 'Επιβεβαίωση',
      message: 'Είστε σίγουροι ότι θέλετε να αποστείλετε την παραγγελία;',
    );

    if (!confirmed) {
      return;
    }

    final tableNumber = _tableController.text.trim();
    try {
      final parentId = widget.mode == WaiterMode.addExtra
          ? await _resolveParentOrderId(tableNumber)
          : null;

      await _api.createOrder(
        tableNumber: tableNumber,
        lines: _orderLines,
        waiterName: _waiterController.text,
        isExtra: widget.mode == WaiterMode.addExtra,
        parentId: parentId,
      );
    } on ApiException catch (e) {
      _showSnack(e.message, palette.error);
      return;
    }

    setState(() {
      _tableController.clear();
      _waiterController.clear();
      _orderLines.clear();
      _removingIds.clear();
      _parentOrderId = null;
    });

    HapticFeedback.heavyImpact();
    _showSnack(
      'Παραγγελία για τραπέζι $tableNumber στάλθηκε!',
      palette.success,
    );
    _announce('Παραγγελία στάλθηκε');
  }

  Future<void> _clearOrder() async {
    final palette = AppPalette.of(context);

    final confirmed = await _confirmDialog(
      title: 'Επιβεβαίωση',
      message: 'Είστε σίγουροι ότι θέλετε να καθαρίσετε την παραγγελία;',
    );

    if (!confirmed) {
      return;
    }

    setState(() {
      _orderLines.clear();
      _removingIds.clear();
    });
    HapticFeedback.lightImpact();
    _showSnack('Η παραγγελία καθαρίστηκε', palette.onSurfaceMuted);
  }

  Future<bool> _confirmDialog({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Ακύρωση'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Επιβεβαίωση'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _announce(String message) {
    SemanticsService.announce(message, Directionality.of(context));
  }

  Future<void> _loadInitialData() async {
    await _refreshMenu(showLoading: true, showErrorState: true);
  }

  Future<void> _refreshMenu({
    required bool showLoading,
    required bool showErrorState,
  }) async {
    if (!mounted) {
      return;
    }

    setState(() {
      if (showLoading) {
        _isLoadingMenu = true;
      }
      _isRefreshingMenu = true;
      if (showErrorState) {
        _menuError = null;
      }
    });

    try {
      final menu = await _api.getMenu();
      if (!mounted) {
        return;
      }
      final sanitizedMenu = menu.where((item) => item.id.isNotEmpty).toList();
      final categories = _extractMenuCategories(sanitizedMenu);
      final selectedCategory = _selectedCategory;
      setState(() {
        _menuProducts = sanitizedMenu;
        if (selectedCategory == null ||
            !categories.contains(selectedCategory)) {
          _selectedCategory = categories.isEmpty ? null : categories.first;
        }
        _isLoadingMenu = false;
        _isRefreshingMenu = false;
        if (showErrorState) {
          _menuError = null;
        }
      });

      if (widget.mode == WaiterMode.addExtra &&
          _tableController.text.trim().isNotEmpty) {
        _parentOrderId = await _resolveParentOrderId(
          _tableController.text.trim(),
        );
        if (mounted) {
          setState(() {});
        }
      }
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingMenu = false;
        _isRefreshingMenu = false;
        if (showErrorState) {
          _menuError = 'Σφάλμα φόρτωσης μενού: ${e.message}';
        }
      });
    }
  }

  Future<String?> _resolveParentOrderId(String tableNumber) async {
    try {
      final orders = await _api.getOrders();
      final tableOrders = orders
          .where(
            (order) =>
                order.tableNumber == tableNumber && order.isAcceptingExtras,
          )
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      final originalOrder = tableOrders.where((order) => !order.isExtra).fold<
        ApiOrderSummary?
      >(
        null,
        (best, current) =>
            best == null || current.timestamp > best.timestamp ? current : best,
      );

      ApiOrderSummary? parentOrder = originalOrder;
      if (parentOrder == null && tableOrders.isNotEmpty) {
        final latest = tableOrders.first;
        if (latest.isExtra && (latest.parentId ?? '').isNotEmpty) {
          parentOrder = orders.where((o) => o.id == latest.parentId).firstOrNull;
        }
        parentOrder ??= latest;
      }

      final rootId = parentOrder?.id;
      final relatedOrders = rootId == null
          ? <ApiOrderSummary>[]
          : tableOrders
                .where(
                  (order) =>
                      order.id == rootId ||
                      (order.isExtra && order.parentId == rootId),
                )
                .toList();

      final resolvedIds = relatedOrders
          .expand((order) => order.items)
          .map((item) => item.id)
          .where((id) => id.trim().isNotEmpty)
          .toSet();
      final resolvedNames = relatedOrders
          .expand((order) => order.items)
          .map((item) => item.name.toLowerCase())
          .where((name) => name.trim().isNotEmpty)
          .toSet();

      if (mounted) {
        setState(() {
          _parentOrderId = rootId;
          _repeatOrderProductIds = resolvedIds;
          _repeatOrderProductNames = resolvedNames;
        });
      } else {
        _parentOrderId = rootId;
        _repeatOrderProductIds = resolvedIds;
        _repeatOrderProductNames = resolvedNames;
      }

      return _parentOrderId;
    } on ApiException {
      return _parentOrderId;
    }
  }

  void _onMenuScroll() {
    if (!_menuGridScrollController.hasClients) {
      return;
    }
    final shouldCollapse = _menuGridScrollController.offset > 20;
    if (shouldCollapse != _isHeaderCollapsed) {
      setState(() {
        _isHeaderCollapsed = shouldCollapse;
      });
    }
  }

  List<String> get _menuCategories => _extractMenuCategories(_menuProducts);

  List<String> _extractMenuCategories(List<MenuProduct> products) {
    final seen = <String>{};
    final categories = <String>[];
    for (final product in products) {
      final category = product.category.trim();
      if (category.isEmpty) {
        continue;
      }
      if (seen.add(category)) {
        categories.add(category);
      }
    }
    return categories;
  }

  Color _categoryColor(String category) {
    final normalized = category.toLowerCase();
    if (normalized.contains('κρύ')) {
      return AppColors.cold;
    }
    if (normalized.contains('ζεστ')) {
      return AppColors.hot;
    }
    if (normalized.contains('ψηστ')) {
      return AppColors.grill;
    }
    if (normalized.contains('μαγειρ')) {
      return AppColors.cooked;
    }
    if (normalized.contains('ποτ') || normalized.contains('αναψ')) {
      return AppColors.drinks;
    }

    const fallback = <Color>[
      AppColors.cold,
      AppColors.hot,
      AppColors.grill,
      AppColors.cooked,
      AppColors.drinks,
    ];
    return fallback[category.hashCode.abs() % fallback.length];
  }
}

class _HeaderInput extends StatelessWidget {
  const _HeaderInput({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xE6FFFFFF),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 48,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: palette.onSurface,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: palette.onSurfaceMuted),
              filled: true,
              fillColor: palette.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuItemCard extends StatefulWidget {
  const _MenuItemCard({required this.item, required this.onTap});

  final MenuProduct item;
  final VoidCallback? onTap;

  @override
  State<_MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<_MenuItemCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final isEnabled = widget.item.active;
    final textColor = isEnabled ? palette.onSurface : palette.onSurfaceMuted;
    final borderColor = _pressed && isEnabled ? AppColors.drinks : palette.outline;

    return Semantics(
      label: '${widget.item.name}, προσθήκη στην παραγγελία',
      button: true,
      enabled: isEnabled,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        scale: _pressed && isEnabled ? 0.98 : 1,
        child: Material(
          color: palette.surface,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (value) {
              if (!isEnabled) {
                return;
              }
              setState(() {
                _pressed = value;
              });
            },
            splashColor: isEnabled
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: borderColor,
                  width: 2,
                ),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (!isEnabled) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: palette.onSurfaceMuted.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: palette.onSurfaceMuted.withValues(alpha: 0.65),
                          ),
                        ),
                        child: Text(
                          'OFF',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: palette.onSurfaceMuted,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderLineCard extends StatelessWidget {
  const _OrderLineCard({
    required this.line,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
    required this.onNote,
  });

  final OrderLine line;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;
  final VoidCallback onNote;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: palette.surfaceContainer.withValues(alpha: isDark ? 0.48 : 0.60),
        border: Border.all(
          color: palette.outline.withValues(alpha: isDark ? 0.70 : 0.80),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      constraints: const BoxConstraints(minHeight: 64),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 400;
          final nameBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: palette.onSurface,
                  height: 1.4,
                ),
              ),
              if ((line.note ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  line.note!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: palette.onSurfaceMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          );

          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Αφαίρεση ${line.product.name}',
                onPressed: onDelete,
                splashRadius: 10,
                padding: EdgeInsets.zero,
                icon: Icon(Icons.delete, color: palette.error, size: 35),
              ),
              IconButton(
                tooltip: 'Προσθήκη σημείωσης για ${line.product.name}',
                onPressed: onNote,
                splashRadius: 24,
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.note_add,
                  color: (line.note ?? '').isNotEmpty
                      ? const Color(0xFF1D4ED8)
                      : AppColors.primary,
                  size: 35,
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                nameBlock,
                const SizedBox(height: 2),
                Row(
                  children: [
                    _buildQuantityControls(palette),
                    const Spacer(),
                    actions,
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: nameBlock),
              const SizedBox(width: 2),
              _buildQuantityControls(palette),
              const SizedBox(width: 2),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuantityControls(AppPalette palette) {
    return SizedBox(
      width: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SquareIconButton(
            semanticsLabel: 'Μείωση ποσότητας ${line.product.name}',
            icon: Icons.remove,
            onTap: onDecrement,
          ),
          const SizedBox(width: 1),
          SizedBox(
            width: 24,
            child: Text(
              '${line.quantity}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: palette.onSurface,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 2),
          _SquareIconButton(
            semanticsLabel: 'Αύξηση ποσότητας ${line.product.name}',
            icon: Icons.add,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.icon,
    required this.onTap,
    required this.semanticsLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: semanticsLabel,
      button: true,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: palette.outline.withValues(alpha: 0.80),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: EdgeInsets.zero,
                backgroundColor: palette.surface.withValues(
                  alpha: isDark ? 0.78 : 0.90,
                ),
              ),
              onPressed: onTap,
              child: Icon(icon, size: 16, color: palette.onSurfaceMuted),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionPanelButton extends StatefulWidget {
  const _ActionPanelButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_ActionPanelButton> createState() => _ActionPanelButtonState();
}

class _ActionPanelButtonState extends State<_ActionPanelButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 150),
      scale: _pressed ? 0.95 : 1,
      child: Material(
        color: widget.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        elevation: widget.icon == Icons.send ? 4 : 2,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.80),
              width: 1.2,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: widget.onTap,
            onHighlightChanged: (value) {
              setState(() {
                _pressed = value;
              });
            },
            child: Center(
              child: Icon(
                widget.icon,
                size: widget.icon == Icons.send ? 32 : 24,
                color: widget.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCategoryState extends StatelessWidget {
  const _EmptyCategoryState();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: AppColors.muted,
          ),
          const SizedBox(height: 8),
          Text(
            'Δεν υπάρχουν προϊόντα σε αυτή την κατηγορία',
            style: TextStyle(
              fontSize: 14,
              color: palette.onSurfaceMuted,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
