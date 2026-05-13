import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'dart:async';
import '../models/mesa.dart';
import '../models/producto.dart';
import '../models/consumo_item.dart';
import '../services/storage_service.dart';
import 'pantalla_historial.dart';
import 'pantalla_productos.dart';
import '../services/session_service.dart';
import 'pantalla_login.dart';
import 'pantalla_usuarios.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  List<Mesa> _mesas = [];
  bool _cargando = true;

  int get _siguienteId {
    if (_mesas.isEmpty) return 1;
    return _mesas.map((m) => m.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  double get _totalDia =>
      _mesas.fold(0.0, (sum, m) => sum + m.gananciasDelDia);

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final datos = await StorageService.cargarMesas();
    setState(() {
      _mesas = datos['mesas'];
      _cargando = false;
    });

    // Reiniciar timers de mesas que estaban activas cuando se cerró la app
    for (var mesa in _mesas) {
      if (mesa.activa) {
        _arrancarTimer(mesa);
      }
    }
  }

  Future<void> _guardar() =>
      StorageService.guardarMesas(_mesas, _siguienteId);

  // ── Vibración ──
  Future<void> _vibrar({bool fuerte = false}) async {
    final tiene = await Vibration.hasVibrator() ?? false;
    if (tiene) {
      fuerte
          ? Vibration.vibrate(duration: 200, amplitude: 255)
          : Vibration.vibrate(duration: 60, amplitude: 128);
    }
    SystemSound.play(SystemSoundType.click);
  }

  // ── CRUD mesas ──
  void _agregarMesa() {
    final numero = _siguienteId;
    setState(() => _mesas.add(Mesa(id: numero, nombre: 'Mesa $numero')));
    _vibrar();
    _guardar();
  }

  void _eliminarMesa(Mesa mesa) {
    mesa.detenerTimer();
    setState(() => _mesas.remove(mesa));
    _vibrar();
    _guardar();
  }

  // ── Ajustar consumo de un producto en una mesa ──
  void _ajustarConsumo(Mesa mesa, Producto producto, int delta) {
    final idx =
        mesa.consumos.indexWhere((c) => c.productoId == producto.id);
    if (idx >= 0) {
      mesa.consumos[idx].cantidad += delta;
      if (mesa.consumos[idx].cantidad <= 0) {
        mesa.consumos.removeAt(idx);
      }
    } else if (delta > 0) {
      mesa.consumos.add(ConsumoItem(
        productoId: producto.id,
        productoNombre: producto.nombre,
        productoPrecio: producto.precio,
        cantidad: 1,
      ));
    }
  }

  // ── Iniciar mesa con producto seleccionado ──
  void _iniciarMesa(Mesa mesa, Producto producto) {
    setState(() {
      mesa.productoMesaId = producto.id;
      mesa.productoMesaNombre = producto.nombre;
      mesa.productoMesaPrecio = producto.precio;
      mesa.activa = true;
      mesa.iniciadoEn = DateTime.now(); // ← Guardamos hora de inicio
      _arrancarTimer(mesa);
    });
    _vibrar();
    _guardar(); // Guardar inmediatamente para persistir el timestamp
  }

  // Arranca el timer de una mesa (separado para reutilizarlo al reabrir la app)
  void _arrancarTimer(Mesa mesa) {
    mesa.timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => mesa.segundos++);
    });
  }

  void _detenerMesa(Mesa mesa) {
    setState(() => mesa.detenerTimer());
    _vibrar(fuerte: true);
    _mostrarResultado(mesa);
  }

  // ── Dialog: seleccionar tipo de mesa para iniciar ──
  Future<void> _mostrarDialogIniciarMesa(Mesa mesa) async {
    // Solo mesas (esMesa == true)
    final todos = await StorageService.cargarProductos();
    final productos = todos.where((p) => p.esMesa).toList();
    if (!mounted) return;

    if (productos.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('⚠️ Sin productos'),
          content: const Text(
            'No hay productos de tipo "Mesa de Billar" configurados.\n\n'
            'Ve a "Productos", agrega una mesa y activa el switch "Tipo: Mesa de Billar".',
          ),
          actions: [
          // Ganancias del día
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.attach_money, color: Colors.greenAccent, size: 18),
              Text('\$${_totalDia.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ]),
          ),
          const SizedBox(width: 4),
          Center(
            child: Text(
              '${_mesas.where((m) => m.activa).length}/${_mesas.length} activas',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),

          // Productos — solo superusuario puede editar precios
          if (SessionService.esSuperusuario)
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PantallaProductos()));
                setState(() {});
              },
              icon: const Icon(Icons.shopping_cart_outlined),
              label: const Text('Productos'),
            ),
          const SizedBox(width: 8),

          // Usuarios — solo superusuario
          if (SessionService.esSuperusuario)
            IconButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PantallaUsuarios())),
              icon: const Icon(Icons.manage_accounts),
              tooltip: 'Gestionar usuarios',
            ),

          // Historial — solo superusuario
          if (SessionService.esSuperusuario)
            IconButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PantallaHistorial())),
              icon: const Icon(Icons.folder_open),
              tooltip: 'Historial mensual',
            ),

          // Resumen del día — todos
          ElevatedButton.icon(
            onPressed: _mostrarResumen,
            icon: const Icon(Icons.bar_chart),
            label: const Text('Resumen del Día'),
          ),
          const SizedBox(width: 8),

          // Usuario actual + cerrar sesión
          PopupMenuButton<String>(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(children: [
                const Icon(Icons.account_circle),
                const SizedBox(width: 6),
                Text(
                  SessionService.usuarioActual?.nombre ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                if (SessionService.esSuperusuario)
                  const Icon(Icons.star, color: Colors.amber, size: 14),
              ]),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'info',
                enabled: false,
                child: Text(
                  SessionService.esSuperusuario ? '⭐ Superusuario' : '👤 Operador',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Cerrar sesión'),
                ]),
              ),
            ],
            onSelected: (val) {
              if (val == 'logout') {
                SessionService.cerrarSesion();
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const PantallaLogin()));
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Producto? seleccionado;
        return StatefulBuilder(
          builder: (ctx, setDialog) => AlertDialog(
            title: Text('🎱 Iniciar ${mesa.nombre}'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selecciona el tipo de mesa (precio por hora):',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: SingleChildScrollView(
                      child: Column(
                        children: productos
                            .map((p) => RadioListTile<Producto>(
                                  title: Text(p.nombre,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                      '\$${p.precio.toStringAsFixed(2)} / hora'),
                                  value: p,
                                  groupValue: seleccionado,
                                  onChanged: (val) =>
                                      setDialog(() => seleccionado = val),
                                  activeColor: Colors.greenAccent,
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar')),
              ElevatedButton.icon(
                onPressed: seleccionado != null
                    ? () {
                        Navigator.pop(ctx);
                        _iniciarMesa(mesa, seleccionado!);
                      }
                    : null,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Iniciar'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Dialog: agregar productos a mesa activa ──
  Future<void> _mostrarDialogConsumos(Mesa mesa) async {
    // Solo consumos (esMesa == false) — excluye las mesas
    final todos = await StorageService.cargarProductos();
    final productos = todos.where((p) => !p.esMesa).toList();
    if (!mounted) return;

    if (productos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay productos de consumo configurados. Agrega productos en el catálogo.'),
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text('🛒 Agregar a ${mesa.nombre}'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: SingleChildScrollView(
                    child: Column(
                      children: productos.map((p) {
                        final items = mesa.consumos
                            .where((c) => c.productoId == p.id);
                        final cantidad =
                            items.isEmpty ? 0 : items.first.cantidad;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: cantidad > 0
                                ? Colors.greenAccent.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: cantidad > 0
                                ? Border.all(
                                    color: Colors.greenAccent
                                        .withOpacity(0.3))
                                : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(p.nombre,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                    Text(
                                        '\$${p.precio.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.red),
                                onPressed: cantidad > 0
                                    ? () => setDialog(
                                        () => setState(() =>
                                            _ajustarConsumo(mesa, p, -1)))
                                    : null,
                              ),
                              SizedBox(
                                width: 32,
                                child: Text(
                                  '$cantidad',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.green),
                                onPressed: () => setDialog(
                                    () => setState(() =>
                                        _ajustarConsumo(mesa, p, 1))),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal consumos:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '\$${mesa.costoConsumos.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 17),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.check),
              label: const Text('Listo'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dialog: mostrar resultado al detener ──
  void _mostrarResultado(Mesa mesa) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('🎱 ${mesa.nombre} — Cuenta Final'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sección de tiempo
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('⏱  TIEMPO DE MESA',
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            letterSpacing: 1)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mesa.productoMesaNombre ?? 'Mesa',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                            Text(
                              '${mesa.tiempoFormateado} × \$${mesa.productoMesaPrecio?.toStringAsFixed(2)}/hr',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                        Text(
                          '\$${mesa.costoTiempo.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Sección de consumos (si hay)
              if (mesa.consumos.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🛒  PRODUCTOS CONSUMIDOS',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              letterSpacing: 1)),
                      const SizedBox(height: 8),
                      ...mesa.consumos.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${c.productoNombre}  ×${c.cantidad}',
                                    style: const TextStyle(fontSize: 15)),
                                Text(
                                  '\$${c.subtotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('💵  TOTAL A COBRAR',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    '\$${mesa.costoTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => mesa.cobrar());
              _guardar();
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('Cobrado ✓ — Continuar'),
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ── Resumen del día ──
  void _mostrarResumen() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('📊 Resumen del Día'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Expanded(
                      child: Text('Mesa',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 13))),
                  Text('Tiempo  ',
                      style:
                          TextStyle(color: Colors.grey, fontSize: 13)),
                  Text('Ganancias',
                      style:
                          TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              const Divider(),
              ..._mesas.map((mesa) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text(mesa.nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold))),
                        Text(mesa.tiempoAcumuladoFormateado,
                            style:
                                const TextStyle(color: Colors.grey)),
                        const SizedBox(width: 16),
                        Text(
                          '\$${mesa.gananciasDelDia.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('GANANCIA TOTAL',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '\$${_totalDia.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 28,
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
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _mostrarDialogCierreDia();
            },
            icon: const Icon(Icons.nights_stay),
            label: const Text('Cerrar el Día'),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
          ),
        ],
      ),
    );
  }

  // ── Confirmar cierre del día ──
  void _mostrarDialogCierreDia() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Cerrar el Día'),
        content: const Text(
          'Esto hará lo siguiente:\n\n'
          '1. Guardará las ganancias de hoy en el reporte mensual\n'
          '2. Reseteará todos los contadores a cero\n\n'
          '¿Estás seguro?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _ejecutarCierreDia();
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('Sí, cerrar el día'),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
          ),
        ],
      ),
    );
  }

  // ── Ejecutar cierre del día ──
  Future<void> _ejecutarCierreDia() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Cerrando el día...'),
        ]),
      ),
    );

    try {
      final double totalDia = _totalDia;

      // 1. Guardar ganancia del día en el reporte mensual
      await StorageService.guardarDiaEnMes(totalDia);

      // 2. Resetear todos los datos del día
      await StorageService.limpiarDia(_mesas, _siguienteId);

      setState(() {});
      _vibrar(fuerte: true);

      if (mounted) Navigator.pop(context);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('✅ ¡Día cerrado!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'Las ganancias fueron guardadas en el historial mensual.'),
                const SizedBox(height: 12),
                Text(
                  'Ganancia del día: \$${totalDia.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 18,
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ve al historial para descargar el reporte mensual.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            actions: [
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.celebration),
                label: const Text('¡Nuevo día! 🎱'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    for (var mesa in _mesas) mesa.detenerTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final columnas = esLandscape ? 4 : 3;

    if (_cargando) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🎱', style: TextStyle(fontSize: 64)),
              SizedBox(height: 16),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Text('🎱', style: TextStyle(fontSize: 26)),
          SizedBox(width: 10),
          Text('Billar Manager',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          // ── Ganancias del día ──
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.attach_money, color: Colors.greenAccent, size: 18),
              Text('\$${_totalDia.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ]),
          ),
          const SizedBox(width: 6),

          // ── Mesas activas ──
          Center(
            child: Text(
              '${_mesas.where((m) => m.activa).length}/${_mesas.length} activas',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          const SizedBox(width: 6),

          // ── Resumen del día (visible para todos) ──
          ElevatedButton.icon(
            onPressed: _mostrarResumen,
            icon: const Icon(Icons.bar_chart, size: 18),
            label: const Text('Resumen'),
          ),
          const SizedBox(width: 6),

          // ── Menú principal con nombre de usuario ──
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_circle, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    SessionService.usuarioActual?.nombre ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  if (SessionService.esSuperusuario)
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
            ),
            itemBuilder: (_) => [
              // ── Info del rol ──
              PopupMenuItem(
                enabled: false,
                child: Text(
                  SessionService.esSuperusuario
                      ? '⭐ Superusuario'
                      : '👤 Operador',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
              const PopupMenuDivider(),

              // ── Opciones solo para superusuario ──
              if (SessionService.esSuperusuario) ...[
                const PopupMenuItem(
                  value: 'productos',
                  child: Row(children: [
                    Icon(Icons.shopping_cart_outlined),
                    SizedBox(width: 12),
                    Text('Listado de Productos'),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'usuarios',
                  child: Row(children: [
                    Icon(Icons.manage_accounts),
                    SizedBox(width: 12),
                    Text('Gestionar Usuarios'),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'historial',
                  child: Row(children: [
                    Icon(Icons.folder_open),
                    SizedBox(width: 12),
                    Text('Historial Mensual'),
                  ]),
                ),
                const PopupMenuDivider(),
              ],

              // ── Cerrar sesión (todos) ──
              const PopupMenuItem(
                value: 'logout',
                child: Row(children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Cerrar sesión',
                      style: TextStyle(color: Colors.red)),
                ]),
              ),
            ],
            onSelected: (val) async {
              switch (val) {
                case 'productos':
                  await Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const PantallaProductos()));
                  setState(() {});
                  break;
                case 'usuarios':
                  await Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const PantallaUsuarios()));
                  break;
                case 'historial':
                  await Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const PantallaHistorial()));
                  break;
                case 'logout':
                  SessionService.cerrarSesion();
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(
                          builder: (_) => const PantallaLogin()));
                  break;
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _mesas.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🎱', style: TextStyle(fontSize: 72)),
                    const SizedBox(height: 16),
                    const Text('No hay mesas registradas',
                        style:
                            TextStyle(fontSize: 22, color: Colors.grey)),
                    const SizedBox(height: 24),
                    if (SessionService.esSuperusuario)
                      ElevatedButton.icon(
                        onPressed: _agregarMesa,
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar Primera Mesa'),
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14)),
                      )
                    else
                      const Text(
                        'El administrador aún no ha configurado las mesas.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              )
            : GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnas,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: esLandscape ? 1.0 : 0.88,
                ),
                itemCount: _mesas.length,
                itemBuilder: (ctx, i) {
                  final mesa = _mesas[i];
                  return _CardMesa(
                    mesa: mesa,
                    onIniciar: () => _mostrarDialogIniciarMesa(mesa),
                    onDetener: () => _detenerMesa(mesa),
                    // Solo superusuario puede eliminar mesas
                    onEliminar: SessionService.esSuperusuario
                        ? () => _eliminarMesa(mesa)
                        : null,
                    onAgregar: () => _mostrarDialogConsumos(mesa),
                  );
                },
              ),
      ),
      floatingActionButton: SessionService.esSuperusuario
          ? FloatingActionButton.extended(
              onPressed: _agregarMesa,
              icon: const Icon(Icons.add),
              label: const Text('Agregar Mesa'),
              backgroundColor: const Color(0xFF2E7D32),
            )
          : null, // ← Operadores no ven el botón
    );
  }
}

// ══════════════════════════════════════════
// WIDGET: CARD DE MESA
// ══════════════════════════════════════════
class _CardMesa extends StatelessWidget {
  final Mesa mesa;
  final VoidCallback onIniciar;
  final VoidCallback onDetener;
  final VoidCallback? onEliminar; // ← Opcional para operadores
  final VoidCallback onAgregar;

  const _CardMesa({
    required this.mesa,
    required this.onIniciar,
    required this.onDetener,
    this.onEliminar, // ← Ya no es required
    required this.onAgregar,
  });

  @override
  Widget build(BuildContext context) {
    final colorPrimario =
        mesa.activa ? const Color(0xFF1B5E20) : const Color(0xFF263238);
    final colorSecundario =
        mesa.activa ? const Color(0xFF2E7D32) : const Color(0xFF37474F);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [colorPrimario, colorSecundario],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: mesa.activa
            ? Border.all(color: Colors.greenAccent, width: 2)
            : Border.all(color: Colors.white10, width: 1),
        boxShadow: mesa.activa
            ? [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.25),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ── Nombre + indicador ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(mesa.nombre,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                if (!mesa.activa && onEliminar != null)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white38),
                      iconSize: 18,
                      onPressed: onEliminar,
                    ),
                if (mesa.activa) const _PulsatingDot(),
              ],
            ),

            // ── Timer ──
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color:
                    mesa.activa ? Colors.greenAccent : Colors.white24,
                fontFamily: 'monospace',
              ),
              child: Text(mesa.tiempoFormateado),
            ),

            // ── Info según estado ──
            Column(
              children: [
                if (mesa.activa && mesa.productoMesaNombre != null)
                  Text(
                    '${mesa.productoMesaNombre} · \$${mesa.productoMesaPrecio?.toStringAsFixed(0)}/hr',
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                if (mesa.activa && mesa.consumos.isNotEmpty)
                  Text(
                    '${mesa.totalItems} productos · \$${mesa.costoConsumos.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.orangeAccent, fontSize: 11),
                  ),
                if (!mesa.activa && mesa.gananciasDelDia > 0)
                  Text(
                    'Hoy: \$${mesa.gananciasDelDia.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.greenAccent, fontSize: 12),
                  ),
              ],
            ),

            // ── Botones ──
            if (mesa.activa)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onAgregar,
                      icon: const Icon(Icons.add_shopping_cart,
                          size: 15),
                      label: const Text('Agregar',
                          style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white30),
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onDetener,
                      icon: const Icon(Icons.stop_rounded, size: 15),
                      label: const Text('Detener',
                          style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onIniciar,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Iniciar',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1B5E20),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Punto pulsante animado ──
class _PulsatingDot extends StatefulWidget {
  const _PulsatingDot();

  @override
  State<_PulsatingDot> createState() => _PulsatingDotState();
}

class _PulsatingDotState extends State<_PulsatingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
      opacity: _anim,
      child: const Icon(Icons.circle, color: Colors.greenAccent, size: 14));
}