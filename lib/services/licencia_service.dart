import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LicenciaService {
  static const String _keyActivada = 'licencia_activada';
  static const String _keyDeviceId = 'licencia_device_id';

  // ── Prefijo secreto — CÁMBIALO antes de distribuir ──
  // Solo tú sabes este valor, nunca lo compartas
  static const String _secreto = 'BILLAR2024XK';

  // ── Obtiene el ID único de la tablet ──
  static Future<String> obtenerDeviceId() async {
    final info = DeviceInfoPlugin();
    final android = await info.androidInfo;
    // Combinamos 2 identificadores para mayor unicidad
    return '${android.id}-${android.serialNumber}';
  }

  // ── Genera el código de licencia válido para este dispositivo ──
  // Este método solo lo usas TÚ como desarrollador
  static Future<String> generarCodigo(String deviceId) async {
    final raw = '$_secreto-$deviceId';
    final bytes = utf8.encode(raw);
    final hash = sha256.convert(bytes).toString();
    // Tomamos los primeros 16 caracteres y los formateamos
    final corto = hash.substring(0, 16).toUpperCase();
    return 'BILLAR-${corto.substring(0, 4)}-'
        '${corto.substring(4, 8)}-'
        '${corto.substring(8, 12)}-'
        '${corto.substring(12, 16)}';
  }

  // ── Verifica si el código ingresado es válido para este dispositivo ──
  static Future<bool> verificarCodigo(String codigoIngresado) async {
    final deviceId = await obtenerDeviceId();
    final codigoCorrecto = await generarCodigo(deviceId);
    return codigoIngresado.trim().toUpperCase() == codigoCorrecto;
  }

  // ── Verifica si la app ya está activada en este dispositivo ──
  static Future<bool> estaActivada() async {
    final prefs = await SharedPreferences.getInstance();
    final activada = prefs.getBool(_keyActivada) ?? false;
    if (!activada) return false;

    // Doble verificación: el deviceId guardado debe coincidir
    final deviceIdGuardado = prefs.getString(_keyDeviceId) ?? '';
    final deviceIdActual = await obtenerDeviceId();
    return deviceIdGuardado == deviceIdActual;
  }

  // ── Activa la licencia en este dispositivo ──
  static Future<void> activar() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = await obtenerDeviceId();
    await prefs.setBool(_keyActivada, true);
    await prefs.setString(_keyDeviceId, deviceId);
  }

  // ── Desactiva (para pruebas) ──
  static Future<void> desactivar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActivada);
    await prefs.remove(_keyDeviceId);
  }
}