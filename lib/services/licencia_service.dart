import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LicenciaService {
  static const String _keyActivada = 'licencia_activada';
  static const String _keyDeviceId = 'licencia_device_id';
  static const String _secreto = 'BILLAR2024XK';

  static Future<String> obtenerDeviceId() async {
    final info = DeviceInfoPlugin();
    final android = await info.androidInfo;
    return '${android.id}-${android.serialNumber}';
  }

  static Future<String> generarCodigo(String deviceId) async {
    final raw = '$_secreto-$deviceId';
    final bytes = utf8.encode(raw);
    final hash = sha256.convert(bytes).toString();
    final corto = hash.substring(0, 16).toUpperCase();
    return 'BILLAR-${corto.substring(0, 4)}-${corto.substring(4, 8)}-${corto.substring(8, 12)}-${corto.substring(12, 16)}';
  }

  static Future<bool> verificarCodigo(String codigoIngresado) async {
    final deviceId = await obtenerDeviceId();
    final codigoCorrecto = await generarCodigo(deviceId);
    return codigoIngresado.trim().toUpperCase() == codigoCorrecto;
  }

  static Future<bool> estaActivada() async {
    final prefs = await SharedPreferences.getInstance();
    final activada = prefs.getBool(_keyActivada) ?? false;
    if (!activada) return false;
    final deviceIdGuardado = prefs.getString(_keyDeviceId) ?? '';
    final deviceIdActual = await obtenerDeviceId();
    return deviceIdGuardado == deviceIdActual;
  }

  static Future<void> activar() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = await obtenerDeviceId();
    await prefs.setBool(_keyActivada, true);
    await prefs.setString(_keyDeviceId, deviceId);
  }

  static Future<void> desactivar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActivada);
    await prefs.remove(_keyDeviceId);
  }
}