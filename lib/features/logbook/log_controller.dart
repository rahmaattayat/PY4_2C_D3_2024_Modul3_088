import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/log_model.dart'; 

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  // Tambahan Homework: List khusus untuk hasil pencarian
  final ValueNotifier<List<LogModel>> filteredLogs = ValueNotifier([]);

  final String username;
  // Key penyimpanan dibuat unik per user agar data tidak tercampur
  String get _storageKey => 'user_logs_data_$username';

  LogController({required this.username}) {
    loadFromDisk();
  }

  void addLog(String title, String desc, String category) {
    final newLog = LogModel(
      title: title,
      description: desc,
      category: category,
      date: DateTime.now().toString(), // Simpan waktu penuh agar unik
    );
    logsNotifier.value = [...logsNotifier.value, newLog];
    filteredLogs.value = logsNotifier.value; // Sync dengan hasil pencarian
    saveToDisk();
  }

  void updateLog(int index, String title, String desc, String category) {
    // Cari index asli berdasarkan tanggal (karena index view bisa berubah saat disearch)
    final targetLog = filteredLogs.value[index];
    final originalIndex = logsNotifier.value.indexWhere((log) => log.date == targetLog.date);

    if (originalIndex != -1) {
      final currentLogs = List<LogModel>.from(logsNotifier.value);
      currentLogs[originalIndex] = LogModel(
        title: title,
        description: desc,
        category: category,
        date: targetLog.date, 
      );
      logsNotifier.value = currentLogs;
      filteredLogs.value = currentLogs; // Reset tampilan ke semula
      saveToDisk();
    }
  }

  void removeLog(int index) {
    final targetLog = filteredLogs.value[index];
    final originalIndex = logsNotifier.value.indexWhere((log) => log.date == targetLog.date);

    if (originalIndex != -1) {
      final currentLogs = List<LogModel>.from(logsNotifier.value);
      currentLogs.removeAt(originalIndex);
      logsNotifier.value = currentLogs;
      filteredLogs.value = currentLogs; // Sync tampilan
      saveToDisk();
    }
  }

  // Tambahan Homework: Fungsi Pencarian (Search)
  void searchLog(String query) {
    if (query.isEmpty) {
      filteredLogs.value = logsNotifier.value;
    } else {
      filteredLogs.value = logsNotifier.value
          .where((log) => log.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  Future<void> saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(
      logsNotifier.value.map((e) => e.toMap()).toList(),
    );
    await prefs.setString(_storageKey, encodedData);
  }

  Future<void> loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data != null) {
      final List decoded = jsonDecode(data);
      logsNotifier.value = decoded.map((e) => LogModel.fromMap(e)).toList();
      filteredLogs.value = logsNotifier.value; // Sync saat pertama kali dibuka
    }
  }
}