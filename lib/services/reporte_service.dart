import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ReporteService {
  // ── Genera el contenido del TXT mensual ──
  static String generarContenidoMensual(
      String mesAnio, List<Map<String, dynamic>> dias) {
    final double totalMes =
        dias.fold(0.0, (sum, d) => sum + (d['total'] as num).toDouble());
    final now = DateTime.now();

    StringBuffer sb = StringBuffer();
    sb.writeln('════════════════════════════════════════');
    sb.writeln('   REPORTE MENSUAL — ${mesAnio.toUpperCase()}');
    sb.writeln('════════════════════════════════════════');
    sb.writeln('');
    sb.writeln('Fecha              Ganancia del día');
    sb.writeln('────────────────────────────────────────');
    for (var dia in dias) {
      final fecha = dia['fecha'].toString().padRight(19);
      final total =
          '\$${(dia['total'] as num).toDouble().toStringAsFixed(2)}';
      sb.writeln('$fecha$total');
    }
    sb.writeln('────────────────────────────────────────');
    sb.writeln('Días trabajados:  ${dias.length}');
    sb.writeln('TOTAL DEL MES:    \$${totalMes.toStringAsFixed(2)}');
    sb.writeln('════════════════════════════════════════');
    sb.writeln('');
    sb.writeln('Generado por Billar Manager');
    sb.writeln(
        'Fecha de generación: ${DateFormat('dd/MM/yyyy HH:mm').format(now)}');
    return sb.toString();
  }

  // ── Genera el TXT y abre el menú de compartir de Android ──
  static Future<void> compartirReporte(
      String key,
      String mesAnio,
      List<Map<String, dynamic>> dias) async {
    final contenido = generarContenidoMensual(mesAnio, dias);
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'billar_${key.replaceFirst('monthly_', '')}.txt';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(contenido);

    // Abre el menú de compartir de Android
    // El usuario puede guardar en Descargas, Drive, WhatsApp, Email, etc.
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Reporte Billar — $mesAnio',
      text: 'Reporte mensual de ganancias — $mesAnio',
    );
  }
}