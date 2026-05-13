import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ReporteService {
  static String generarContenidoMensual(
      String mesAnio, List<Map<String, dynamic>> dias) {
    final double totalMes =
        dias.fold(0.0, (sum, d) => sum + (d['total'] as num).toDouble());
    final now = DateTime.now();

    StringBuffer sb = StringBuffer();
    sb.writeln('========================================');
    sb.writeln('   REPORTE MENSUAL — ${mesAnio.toUpperCase()}');
    sb.writeln('========================================');
    sb.writeln('');
    sb.writeln('Fecha              Ganancia del dia');
    sb.writeln('----------------------------------------');
    for (var dia in dias) {
      final fecha = dia['fecha'].toString().padRight(19);
      final total = '\$${(dia['total'] as num).toDouble().toStringAsFixed(2)}';
      sb.writeln('$fecha$total');
    }
    sb.writeln('----------------------------------------');
    sb.writeln('Dias trabajados:  ${dias.length}');
    sb.writeln('TOTAL DEL MES:    \$${totalMes.toStringAsFixed(2)}');
    sb.writeln('========================================');
    sb.writeln('');
    sb.writeln('Generado por Billar Manager');
    sb.writeln('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(now)}');
    return sb.toString();
  }

  static Future<void> compartirReporte(
      String key, String mesAnio, List<Map<String, dynamic>> dias) async {
    final contenido = generarContenidoMensual(mesAnio, dias);
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'billar_${key.replaceFirst('monthly_', '')}.txt';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(contenido);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Reporte Billar — $mesAnio',
      text: 'Reporte mensual de ganancias — $mesAnio',
    );
  }
}