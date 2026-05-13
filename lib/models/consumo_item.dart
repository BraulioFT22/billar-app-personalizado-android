class ConsumoItem {
  final String productoId;
  final String productoNombre;
  final double productoPrecio;
  int cantidad;

  ConsumoItem({
    required this.productoId,
    required this.productoNombre,
    required this.productoPrecio,
    this.cantidad = 1,
  });

  double get subtotal => productoPrecio * cantidad;
}