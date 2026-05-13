import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/reporte_service.dart';

class PantallaHistorial extends StatefulWidget {
  const PantallaHistorial({super.key});

  @override
  State<PantallaHistorial> createState() => _PantallaHistorialState();
}

class _PantallaHistorialState extends State<PantallaHistorial> {
  List<Map<String, dynamic>> _meses = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final meses = await StorageService.cargarMesesDisponibles();
    setState(() {
      _meses = meses;
      _cargando = false;
    });
  }

  void _verDetalle(Map<String, dynamic> mes) {
    final dias = mes['dias'] as List<Map<String, dynamic>>;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          const Text('📅 '),
          Text(mes['mesAnio'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Encabezado
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Fecha',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                  Text('Ganancia',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              const Divider(),
              // Días
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: SingleChildScrollView(
                  child: Column(
                    children: dias.map((d) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(d['fecha'].toString(),
                              style: const TextStyle(fontSize: 15)),
                          Text(
                            '\$${(d['total'] as num).toDouble().toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL DEL MES',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '\$${(mes['totalMes'] as double).toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Future<void> _descargar(Map<String, dynamic> mes) async {
    try {
      await ReporteService.compartirReporte(
        mes['key'] as String,
        mes['mesAnio'] as String,
        mes['dias'] as List<Map<String, dynamic>>,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📁 Historial Mensual'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _meses.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('📂', style: TextStyle(fontSize: 64)),
                      SizedBox(height: 16),
                      Text(
                        'No hay reportes aún.\nRealiza un cierre del día para generar el primero.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _meses.length,
                  itemBuilder: (ctx, i) {
                    final mes = _meses[i];
                    final dias =
                        mes['dias'] as List<Map<String, dynamic>>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Text('📅',
                                style: TextStyle(fontSize: 36)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mes['mesAnio'] as String,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${dias.length} días trabajados',
                                    style: const TextStyle(
                                        color: Colors.grey),
                                  ),
                                  Text(
                                    'Total: \$${(mes['totalMes'] as double).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _verDetalle(mes),
                              icon: const Icon(Icons.visibility),
                              label: const Text('Ver detalle'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _descargar(mes),
                              icon: const Icon(Icons.download),
                              label: const Text('Descargar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}