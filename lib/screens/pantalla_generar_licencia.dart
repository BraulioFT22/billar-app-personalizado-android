import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/licencia_service.dart';

class PantallaGenerarLicencia extends StatefulWidget {
  const PantallaGenerarLicencia({super.key});

  @override
  State<PantallaGenerarLicencia> createState() =>
      _PantallaGenerarLicenciaState();
}

class _PantallaGenerarLicenciaState
    extends State<PantallaGenerarLicencia> {
  final _deviceIdCtrl = TextEditingController();
  String _codigoGenerado = '';
  String _claveCtrl = '';
  // ⚠️ Clave secreta de desarrollador — CÁMBIALA
  static const String _claveDesarrollador = 'DEV2024';

  void _generar() {
    if (_claveCtrl != _claveDesarrollador) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Clave de desarrollador incorrecta'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_deviceIdCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el Device ID del cliente')),
      );
      return;
    }

    LicenciaService.generarCodigo(_deviceIdCtrl.text.trim())
        .then((codigo) {
      setState(() => _codigoGenerado = codigo);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔑 Generador de Licencias'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '⚠️ PANEL DE DESARROLLADOR',
                style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'Solo para uso interno. No compartas esta pantalla.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 32),

              // Clave de desarrollador
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Clave de desarrollador',
                  prefixIcon: Icon(Icons.security),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _claveCtrl = v,
              ),
              const SizedBox(height: 16),

              // Device ID del cliente
              TextField(
                controller: _deviceIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Device ID del cliente',
                  hintText: 'El cliente te lo envía desde la app',
                  prefixIcon: Icon(Icons.phone_android),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generar,
                  icon: const Icon(Icons.key),
                  label: const Text('Generar Código de Licencia'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.black,
                  ),
                ),
              ),

              // Resultado
              if (_codigoGenerado.isNotEmpty) ...[
                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 16),
                const Text('Código generado:',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.greenAccent),
                  ),
                  child: Column(
                    children: [
                      SelectableText(
                        _codigoGenerado,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.greenAccent,
                          letterSpacing: 2,
                          fontFamily: 'monospace',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: _codigoGenerado));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('✅ Código copiado al portapapeles'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copiar código'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Envía este código al cliente por WhatsApp o email.\nEs válido ÚNICAMENTE para su dispositivo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}