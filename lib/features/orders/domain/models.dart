import 'package:flutter/material.dart';

enum WaiterMode { newOrder, addExtra }

class MenuProduct {
  const MenuProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.active,
  });

  final String id;
  final String name;
  final String category;
  final bool active;

  static MenuProduct? fromApiJson(Map<String, dynamic> json) {
    final rawCategory = json['category']?.toString().trim() ?? '';
    if (rawCategory.isEmpty) {
      return null;
    }

    return MenuProduct(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: rawCategory,
      active: _parseActive(json['active']),
    );
  }

  static bool _parseActive(dynamic raw) {
    if (raw is bool) {
      return raw;
    }
    if (raw is num) {
      return raw != 0;
    }
    final text = raw?.toString().trim().toLowerCase() ?? '';
    if (text == 'false' || text == '0' || text == 'no') {
      return false;
    }
    return true;
  }
}

class OrderLine {
  OrderLine({
    required this.product,
    required this.quantity,
    this.note,
  });

  final MenuProduct product;
  int quantity;
  String? note;
}

class ApiOrderItemSummary {
  const ApiOrderItemSummary({
    required this.id,
    required this.name,
    required this.quantity,
    required this.category,
    required this.itemStatus,
    required this.units,
  });

  final String id;
  final String name;
  final int quantity;
  final String category;
  final String itemStatus;
  final List<ApiOrderUnitSummary> units;

  factory ApiOrderItemSummary.fromJson(Map<String, dynamic> json) {
    final units = json['units'];
    final parsedUnits = units is List
        ? units
            .whereType<Map<String, dynamic>>()
            .map(ApiOrderUnitSummary.fromJson)
            .toList()
        : const <ApiOrderUnitSummary>[];

    return ApiOrderItemSummary(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      category: json['category']?.toString() ?? 'Άλλη',
      itemStatus: json['itemStatus']?.toString() ?? 'new',
      units: parsedUnits,
    );
  }
}

class ApiOrderUnitSummary {
  const ApiOrderUnitSummary({required this.status});

  final String status;

  factory ApiOrderUnitSummary.fromJson(Map<String, dynamic> json) {
    return ApiOrderUnitSummary(status: json['status']?.toString() ?? 'new');
  }
}

class ApiOrderSummary {
  const ApiOrderSummary({
    required this.id,
    required this.tableNumber,
    required this.waiterName,
    required this.itemsCount,
    required this.items,
    required this.timestamp,
    required this.status,
    required this.isExtra,
    required this.parentId,
  });

  final String id;
  final String tableNumber;
  final String waiterName;
  final int itemsCount;
  final List<ApiOrderItemSummary> items;
  final int timestamp;
  final String status;
  final bool isExtra;
  final String? parentId;

  bool get isAcceptingExtras =>
      status != 'closed' && status != 'cancelled' && status != 'delivered';

  factory ApiOrderSummary.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    final parsedItems = items is List
        ? items
            .whereType<Map<String, dynamic>>()
            .map(ApiOrderItemSummary.fromJson)
            .toList()
        : const <ApiOrderItemSummary>[];
    final itemsCount = parsedItems.length;

    return ApiOrderSummary(
      id: json['id']?.toString() ?? '',
      tableNumber: json['tableNumber']?.toString() ?? '',
      waiterName: json['waiterName']?.toString() ?? '',
      itemsCount: itemsCount,
      items: parsedItems,
      timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'pending',
      isExtra: json['isExtra'] == true,
      parentId: json['parentId']?.toString(),
    );
  }
}
