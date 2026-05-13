import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/usuario.dart';
import '../services/database_service.dart';
import '../services/session_service.dart';
import 'pantalla_principal.dart';
import 'pantalla_generar_licencia.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final _pinCtrl = TextEditingController();
  bool _cargando = true;
  bool _necesitaSetup = false;
  String _error = '';
  int _toquesBillar = 0;

  final _nombreCtrl = TextEditingController();
  final _pin2Ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _verificarSetup();
  }

  Future<void> _verificarSetup() async {
    final existe = await DatabaseService.existeSuperusuario();
    setState(() {
      _necesitaSetup = !existe;
      _cargando = false;
    });
  }

  Future<void> _crearSuperusuario() async {
    final nombre = _nombreCtrl.text.trim();
    final pin = _pinCtrl.text.trim();
    final pin2 = _pin2Ctrl.text.trim();

    if (nombre.isEmpty) {
      setState(() => _error = 'Ingresa tu nombre');
      return;
    }
    if (pin.length < 4) {
      setState(() => _error = 'El PIN debe tener al menos 4 dígitos');
      return;
    }
    if (pin != pin2) {
      setState(() => _error = 'Los PINs no coinciden');
      return;
    }

    setState(() => _cargando = true);
    await DatabaseService.crearSuperusuario(nombre, pin);

    final usuario = await DatabaseService.login(pin);
    if (usuario != null && mounted) {
      SessionService.iniciarSesion(usuario);
      _irAlDashboard();
    }
  }

  Future<void> _login() async {
    final pin = _pinCtrl.text.trim();
    if (pin.isEmpty) {
      setState(() => _error = 'Ingresa tu PIN');
      return;
    }

    setState(() => _cargando = true);
    final usuario = await DatabaseService.login(pin);

    if (usuario != null && mounted) {
      SessionService.iniciarSesion(usuario);
      _irAlDashboard();
    } else {
      setState(() {
        _error = 'PIN incorrecto';
        _cargando = false;
      });
      HapticFeedback.mediumImpact();
    }
  }

  void _irAlDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PantallaPrincipal()),
    );
  }

  Widget _tecladoPin() {
    final numeros = ['1','2','3','4','5','6','7','8','9','','0','⌫'];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: numeros.length,
      itemBuilder: (ctx, i) {
        final n = numeros[i];
        if (n.isEmpty) return const SizedBox();
        return ElevatedButton(
          onPressed: () {
            setState(() {
              _error = '';
              if (n == '⌫') {
                if (_pinCtrl.text.isNotEmpty) {
                  _pinCtrl.text =
                      _pinCtrl.text.substring(0, _pinCtrl.text.length - 1);
                }
              } else if (_pinCtrl.text.length < 6) {
                _pinCtrl.text += n;
              }
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white12,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(n,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold)),
        );
      },
    );
  }

  Widget _indicadorPin(String valor, {int maxLen = 6}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxLen, (i) {
        final lleno = i < valor.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: lleno ? Colors.greenAccent : Colors.white24,
            border: Border.all(
              color: lleno ? Colors.greenAccent : Colors.white38,
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: _necesitaSetup
              ? _pantallaSetup()
              : _pantallaLoginNormal(),
        ),
      ),
    );
  }

  Widget _pantallaSetup() {
    return Container(
      width: 420,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎱', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 8),
          const Text('Billar Manager',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Configuración inicial',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          const Text(
            'Crea tu cuenta de Superusuario.\nEsta cuenta tendrá acceso total al sistema.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nombreCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Tu nombre',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pinCtrl,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'PIN (4-6 dígitos)',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pin2Ctrl,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Confirmar PIN',
              prefixIcon: Icon(Icons.lock_outline),
              border: OutlineInputBorder(),
            ),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_error,
                style: const TextStyle(color: Colors.red, fontSize: 14)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _crearSuperusuario,
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('Crear Superusuario y Entrar'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pantallaLoginNormal() {
    return Container(
      width: 380,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Toca 7 veces para modo desarrollador ──
          GestureDetector(
            onTap: () {
              setState(() => _toquesBillar++);
              if (_toquesBillar >= 7) {
                _toquesBillar = 0;
                _mostrarMenuDesarrollador();
              }
            },
            child: const Text('🎱', style: TextStyle(fontSize: 56)),
          ),
          const SizedBox(height: 8),
          const Text('Billar Manager',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Ingresa tu PIN',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 28),
          _indicadorPin(_pinCtrl.text),
          const SizedBox(height: 8),
          if (_error.isNotEmpty)
            Text(_error,
                style:
                    const TextStyle(color: Colors.redAccent, fontSize: 14)),
          const SizedBox(height: 16),
          _tecladoPin(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _login,
              icon: const Icon(Icons.login),
              label: const Text('Entrar', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // MODO DESARROLLADOR — toca 🎱 siete veces
  // ══════════════════════════════════════════

  void _mostrarMenuDesarrollador() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.developer_mode, color: Colors.amber),
          SizedBox(width: 8),
          Text('Modo Desarrollador'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Selecciona el usuario a resetear:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Usuario>>(
              future: _obtenerTodosUsuarios(),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const CircularProgressIndicator();
                }
                if (snap.data!.isEmpty) {
                  return const Text(
                    'No hay usuarios registrados.',
                    style: TextStyle(color: Colors.grey),
                  );
                }
                return Column(
                  children: snap.data!
                      .map((u) => ListTile(
                            leading: Icon(
                              u.esSuperusuario
                                  ? Icons.star
                                  : Icons.person,
                              color: u.esSuperusuario
                                  ? Colors.amber
                                  : Colors.grey,
                            ),
                            title: Text(u.nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              u.esSuperusuario
                                  ? 'Superusuario'
                                  : 'Operador',
                              style:
                                  const TextStyle(color: Colors.grey),
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _mostrarResetPin(u);
                              },
                              child: const Text('Resetear PIN'),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
        actions: [
          // ── Acceso al generador de licencias ──
          TextButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PantallaGenerarLicencia()),
              );
            },
            icon: const Icon(Icons.key, color: Colors.amber),
            label: const Text('Generar Licencia',
                style: TextStyle(color: Colors.amber)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<List<Usuario>> _obtenerTodosUsuarios() async {
    final database = await DatabaseService.db;
    final result = await database.query('usuarios');
    return result.map((m) => Usuario.fromMap(m)).toList();
  }

  void _mostrarResetPin(Usuario usuario) {
    final pinCtrl = TextEditingController();
    final pin2Ctrl = TextEditingController();
    String error = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text('🔑 Nuevo PIN — ${usuario.nombre}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nuevo PIN (4-6 dígitos)',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: pin2Ctrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Confirmar nuevo PIN',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              if (error.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(error,
                    style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (pinCtrl.text.length < 4) {
                  setDialog(() => error = 'Mínimo 4 dígitos');
                  return;
                }
                if (pinCtrl.text != pin2Ctrl.text) {
                  setDialog(() => error = 'Los PINs no coinciden');
                  return;
                }
                await DatabaseService.cambiarPin(
                    usuario.id!, pinCtrl.text);
                if (mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '✅ PIN de ${usuario.nombre} actualizado'),
                      backgroundColor: Colors.green[700],
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Guardar PIN'),
            ),
          ],
        ),
      ),
    );
  }
}