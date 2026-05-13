import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mesa.dart';
import '../models/producto.dart';

class StorageService {
  static const String _keyMesas = 'mesas_data';
  static const String _keyContadorId = 'contador_id';
  static const String _keyProductos = 'productos_data';

  static Future<void> guardarMesas(List<Mesa> mesas, int contadorId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _keyMesas, jsonEncode(mesas.map((m) => m.toMap()).toList()));
    await prefs.setInt(_keyContadorId, contadorId);
  }

  static Future<Map<String, dynamic>> cargarMesas() async {
    final prefs = await SharedPreferences.getInstance();
    final String? json = prefs.getString(_keyMesas);
    final int contadorId = prefs.getInt(_keyContadorId) ?? 1;
    if (json == null) {
      return {'mesas': <Mesa>[], 'contadorId': 1};
    }
    final List<dynamic> lista = jsonDecode(json);
    return {
      'mesas': lista.map((m) => Mesa.fromMap(m)).toList(),
      'contadorId': contadorId,
    };
  }

  static Future<void> limpiarDia(List<Mesa> mesas, int contadorId) async {
    for (var mesa in mesas) mesa.resetearDia();
    await guardarMesas(mesas, contadorId);
  }

  static Future<void> guardarProductos(List<Producto> productos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _keyProductos, jsonEncode(productos.map((p) => p.toMap()).toList()));
  }

  static Future<List<Producto>> cargarProductos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? json = prefs.getString(_keyProductos);
    if (json == null) return [];
    final List<dynamic> lista = jsonDecode(json);
    return lista.map((p) => Producto.fromMap(p)).toList();
  }

  static String _keyMes(DateTime fecha) =>
      'monthly_${fecha.year}_${fecha.month.toString().padLeft(2, '0')}';

  static Future<void> guardarDiaEnMes(double totalDia) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final key = _keyMes(now);
    final String fechaStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final String? existing = prefs.getString(key);
    List<Map<String, dynamic>> dias = [];
    if (existing != null) {
      dias = List<Map<String, dynamic>>.from(jsonDecode(existing));
    }
    final int idx = dias.indexWhere((d) => d['fecha'] == fechaStr);
    if (idx >= 0) {
      dias[idx]['total'] = (dias[idx]['total'] as num).toDouble() + totalDia;
    } else {
      dias.add({'fecha': fechaStr, 'total': totalDia});
    }
    await prefs.setString(key, jsonEncode(dias));
  }

  static Future<List<Map<String, dynamic>>> cargarMesesDisponibles() async {
    final prefs = await SharedPreferences.getInstance();
    final keys =
        prefs.getKeys().where((k) => k.startsWith('monthly_')).toList();
    keys.sort((a, b) => b.compareTo(a));
    List<Map<String, dynamic>> meses = [];
    for (var key in keys) {
      final String? data = prefs.getString(key);
      if (data == null) continue;
      final List<dynamic> dias = jsonDecode(data);
      final double totalMes =
          dias.fold(0.0, (sum, d) => sum + (d['total'] as num).toDouble());
      meses.add({
        'key': key,
        'mesAnio': _keyToLabel(key),
        'totalMes': totalMes,
        'dias': List<Map<String, dynamic>>.from(dias),
      });
    }
    return meses;
  }

  static String _keyToLabel(String key) {
    final parts = key.replaceFirst('monthly_', '').split('_');
    if (parts.length != 2) return key;
    final meses = [
      'Enero','Febrero','Marzo','Abril','Mayo','Junio',
      'Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'
    ];
    final month = int.tryParse(parts[1]) ?? 1;
    return '${meses[month - 1]} ${parts[0]}';
  }
}