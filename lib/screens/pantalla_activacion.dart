import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/licencia_service.dart';
import 'pantalla_login.dart';

class PantallaActivacion extends StatefulWidget {
  const PantallaActivacion({super.key});

  @override
  State<PantallaActivacion> createState() => _PantallaActivacionState();
}

class _PantallaActivacionState extends State<PantallaActivacion> {
  final _codigoCtrl = TextEditingController();
  String _deviceId = '';
  String _error = '';
  bool _cargando = false;
  bool _verificando = true;

  // Controles para los 4 segmentos del código
  final _seg1 = TextEditingController();
  final _seg2 = TextEditingController();
  final _seg3 = TextEditingController();
  final _seg4 = TextEditingController();
  final _f1 = FocusNode();
  final _f2 = FocusNode();
  final _f3 = FocusNode();
  final _f4 = FocusNode();

  @override
  void initState() {
    super.initState();
    _cargarDeviceId();
  }

  @override
  void dispose() {
    _seg1.dispose(); _seg2.dispose();
    _seg3.dispose(); _seg4.dispose();
    _f1.dispose(); _f2.dispose();
    _f3.dispose(); _f4.dispose();
    super.dispose();
  }

  Future<void> _cargarDeviceId() async {
    final id = await LicenciaService.obtenerDeviceId();
    setState(() {
      _deviceId = id;
      _verificando = false;
    });
  }

  // ── Avanza al siguiente campo automáticamente ──
  void _onSegmentoChanged(String val, TextEditingController ctrl,
      FocusNode actual, FocusNode? siguiente) {
    if (val.length == 4 && siguiente != null) {
      siguiente.requestFocus();
    }
    setState(() => _error = '');
  }

  Future<void> _activar() async {
    final codigo =
        'BILLAR-${_seg1.text.toUpperCase()}-${_seg2.text.toUpperCase()}'
        '-${_seg3.text.toUpperCase()}-${_seg4.text.toUpperCase()}';

    if (_seg1.text.length < 4 || _seg2.text.length < 4 ||
        _seg3.text.length < 4 || _seg4.text.length < 4) {
      setState(() => _error = 'Ingresa el código completo');
      return;
    }

    setState(() => _cargando = true);
    final valido = await LicenciaService.verificarCodigo(codigo);

    if (valido) {
      await LicenciaService.activar();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PantallaLogin()),
        );
      }
    } else {
      setState(() {
        _error = 'Código incorrecto. Contacta al desarrollador.';
        _cargando = false;
      });
      HapticFeedback.mediumImpact();
    }
  }

  // ── Campo de segmento del código ──
  Widget _campoSegmento(TextEditingController ctrl, FocusNode foco,
      FocusNode? siguiente) {
    return SizedBox(
      width: 72,
      child: TextField(
        controller: ctrl,
        focusNode: foco,
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.characters,
        maxLength: 4,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 3,
        ),
        decoration: InputDecoration(
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Colors.greenAccent, width: 2),
          ),
        ),
        onChanged: (val) =>
            _onSegmentoChanged(val, ctrl, foco, siguiente),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_verificando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: Colors.greenAccent.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Ícono y título ──
                const Text('🔐', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                const Text(
                  'Activación de Licencia',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Esta app requiere una licencia válida.\nContacta al desarrollador para obtener tu código.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),

                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 16),

                // ── ID del dispositivo (para que el cliente te lo envíe) ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'ID de tu dispositivo',
                        style: TextStyle(
                            color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        _deviceId,
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Botón copiar ID
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: _deviceId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ID copiado al portapapeles'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copiar ID',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Ingreso del código ──
                const Text(
                  'Ingresa tu código de activación:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Formato: BILLAR-XXXX-XXXX-XXXX-XXXX',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 16),

                // ── 4 campos de segmento ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('BILLAR-',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey)),
                    _campoSegmento(_seg1, _f1, _f2),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('-',
                          style: TextStyle(
                              fontSize: 20, color: Colors.grey)),
                    ),
                    _campoSegmento(_seg2, _f2, _f3),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('-',
                          style: TextStyle(
                              fontSize: 20, color: Colors.grey)),
                    ),
                    _campoSegmento(_seg3, _f3, _f4),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('-',
                          style: TextStyle(
                              fontSize: 20, color: Colors.grey)),
                    ),
                    _campoSegmento(_seg4, _f4, null),
                  ],
                ),

                // ── Error ──
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(_error,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 14),
                      textAlign: TextAlign.center),
                ],

                const SizedBox(height: 24),

                // ── Botón activar ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _cargando ? null : _activar,
                    icon: _cargando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          )
                        : const Icon(Icons.verified),
                    label: Text(
                      _cargando ? 'Verificando...' : 'Activar Licencia',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF2E7D32),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Text(
                  'Billar Manager © 2024\nDesarrollado por ti',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}