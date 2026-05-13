import 'dart:async';
import 'consumo_item.dart';

class Mesa {
  int id;
  String nombre;
  bool activa;
  int segundos;
  int segundosAcumulados;
  double gananciasDelDia;
  Timer? timer;
  DateTime? iniciadoEn;
  String? productoMesaId;
  String? productoMesaNombre;
  double? productoMesaPrecio;
  List<ConsumoItem> consumos;

  Mesa({
    required this.id,
    required this.nombre,
    this.activa = false,
    this.segundos = 0,
    this.segundosAcumulados = 0,
    this.gananciasDelDia = 0.0,
    this.productoMesaId,
    this.productoMesaNombre,
    this.productoMesaPrecio,
    List<ConsumoItem>? consumos,
  }) : consumos = consumos ?? [];

  String get tiempoFormateado {
    int h = segundos ~/ 3600;
    int m = (segundos % 3600) ~/ 60;
    int s = segundos % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get tiempoAcumuladoFormateado {
    int h = segundosAcumulados ~/ 3600;
    int m = (segundosAcumulados % 3600) ~/ 60;
    return '${h.toString().padLeft(2, '0')}h ${m.toString().padLeft(2, '0')}m';
  }

  double get costoTiempo {
    if (productoMesaPrecio == null) return 0.0;
    return (segundos / 3600) * productoMesaPrecio!;
  }

  double get costoConsumos =>
      consumos.fold(0.0, (sum, c) => sum + c.subtotal);

  double get costoTotal => costoTiempo + costoConsumos;

  int get totalItems => consumos.fold(0, (sum, c) => sum + c.cantidad);

  void detenerTimer() {
    timer?.cancel();
    timer = null;
    activa = false;
    iniciadoEn = null;
  }

  void cobrar() {
    gananciasDelDia += costoTotal;
    segundosAcumulados += segundos;
    detenerTimer();
    segundos = 0;
    productoMesaId = null;
    productoMesaNombre = null;
    productoMesaPrecio = null;
    consumos = [];
  }

  void resetearDia() {
    detenerTimer();
    segundos = 0;
    segundosAcumulados = 0;
    productoMesaId = null;
    productoMesaNombre = null;
    productoMesaPrecio = null;
    consumos = [];
    gananciasDelDia = 0.0;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'segundosAcumulados': segundosAcumulados,
        'gananciasDelDia': gananciasDelDia,
        'activa': activa,
        'iniciadoEn': iniciadoEn?.millisecondsSinceEpoch,
        'segundosBase': segundos,
        'productoMesaId': productoMesaId,
        'productoMesaNombre': productoMesaNombre,
        'productoMesaPrecio': productoMesaPrecio,
        'consumos': consumos.map((c) => {
              'productoId': c.productoId,
              'productoNombre': c.productoNombre,
              'productoPrecio': c.productoPrecio,
              'cantidad': c.cantidad,
            }).toList(),
      };

  factory Mesa.fromMap(Map<String, dynamic> map) {
    final mesa = Mesa(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      segundosAcumulados: (map['segundosAcumulados'] as num?)?.toInt() ?? 0,
      gananciasDelDia: (map['gananciasDelDia'] as num?)?.toDouble() ?? 0.0,
      productoMesaId: map['productoMesaId'] as String?,
      productoMesaNombre: map['productoMesaNombre'] as String?,
      productoMesaPrecio: (map['productoMesaPrecio'] as num?)?.toDouble(),
    );
    if (map['consumos'] != null) {
      for (var c in map['consumos'] as List) {
        mesa.consumos.add(ConsumoItem(
          productoId: c['productoId'] as String,
          productoNombre: c['productoNombre'] as String,
          productoPrecio: (c['productoPrecio'] as num).toDouble(),
          cantidad: c['cantidad'] as int,
        ));
      }
    }
    if (map['activa'] == true && map['iniciadoEn'] != null) {
      final iniciadoEn = DateTime.fromMillisecondsSinceEpoch(map['iniciadoEn'] as int);
      final segundosBase = (map['segundosBase'] as num?)?.toInt() ?? 0;
      final transcurridos = DateTime.now().difference(iniciadoEn).inSeconds;
      mesa.segundos = segundosBase + transcurridos;
      mesa.iniciadoEn = iniciadoEn;
      mesa.activa = true;
    }
    return mesa;
  }
}