class Producto {
  final String id;
  String nombre;
  double precio;
  bool esMesa; // true = aparece al INICIAR mesa | false = aparece en CONSUMOS

  Producto({
    required this.id,
    required this.nombre,
    required this.precio,
    this.esMesa = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'precio': precio,
        'esMesa': esMesa,
      };

  factory Producto.fromMap(Map<String, dynamic> map) => Producto(
        id: map['id'] as String,
        nombre: map['nombre'] as String,
        precio: (map['precio'] as num).toDouble(),
        esMesa: map['esMesa'] as bool? ?? false,
      );
}