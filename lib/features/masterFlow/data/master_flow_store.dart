import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SavedMasterFlow {
  const SavedMasterFlow({
    required this.name,
    required this.activities,
    this.reference = '',
    this.senderCompany = '',
  });

  final String name;
  final String reference;
  final String senderCompany;
  final List<Map<String, String>> activities;

  String get startingCompany =>
      activities.isEmpty ? '' : activities.first['company'] ?? '';

  List<Map<String, String>> get checkSheets => activities.indexed
      .map(
        (entry) => {
          'number': '${entry.$1 + 1}',
          'activity': entry.$2['name'] ?? '',
          'reference': entry.$2['reference'] ?? '',
          'company': entry.$2['company'] ?? '',
        },
      )
      .toList();

  Map<String, dynamic> toJson() => {
    'name': name,
    'reference': reference,
    'senderCompany': senderCompany,
    'activities': activities,
    'checkSheets': checkSheets,
  };

  factory SavedMasterFlow.fromJson(Map<String, dynamic> json) =>
      SavedMasterFlow(
        name: json['name'] as String,
        reference: json['reference'] as String? ?? '',
        senderCompany: json['senderCompany'] as String? ?? '',
        activities: (json['activities'] as List)
            .map((item) => Map<String, String>.from(item as Map))
            .toList(),
      );
}

class MasterFlowStore {
  const MasterFlowStore({required this.project, required this.company});
  final String project;
  final String company;

  String get _key => 'master_flows_v1:${jsonEncode([project, company])}';

  Future<List<SavedMasterFlow>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_key);
    return saved == null
        ? []
        : (jsonDecode(saved) as List)
              .map(
                (item) => SavedMasterFlow.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList();
  }

  Future<void> save(SavedMasterFlow flow, {String? previousName}) async {
    final items = await load();
    final index = items.indexWhere(
      (item) =>
          item.name.trim().toLowerCase() == (previousName ?? flow.name).trim().toLowerCase(),
    );
    if (index < 0) {
      items.add(flow);
    } else {
      items[index] = flow;
    }
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setString(
      _key,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    )) {
      throw StateError('Unable to save master flow');
    }
  }
}
