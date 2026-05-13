import 'package:flutter/material.dart';

class Producto {
  final String id;
  String nombre;
  double precio;
  bool esMesa;
  String iconoClave;

  Producto({
    required this.id,
    required this.nombre,
    required this.precio,
    this.esMesa = false,
    this.iconoClave = 'sports_bar',
  });

  IconData get icono => CatalogoIconos.obtener(iconoClave);

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'precio': precio,
        'esMesa': esMesa,
        'iconoClave': iconoClave,
      };

  factory Producto.fromMap(Map<String, dynamic> map) => Producto(
        id: map['id'] as String,
        nombre: map['nombre'] as String,
        precio: (map['precio'] as num).toDouble(),
        esMesa: map['esMesa'] as bool? ?? false,
        iconoClave: map['iconoClave'] as String? ?? 'sports_bar',
      );
}

class CatalogoIconos {
  static const Map<String, Map<String, dynamic>> todos = {
    'billiards':         {'icono': Icons.circle,               'categoria': 'Billar',    'label': 'Mesa Billar'},
    'sports_bar':        {'icono': Icons.sports_bar,           'categoria': 'Billar',    'label': 'Taco'},
    'radio_button':      {'icono': Icons.radio_button_checked, 'categoria': 'Billar',    'label': 'Bola'},
    'category':          {'icono': Icons.category,             'categoria': 'Billar',    'label': 'Tiza'},
    'table_bar':         {'icono': Icons.table_bar,            'categoria': 'Billar',    'label': 'Mesa'},
    'local_bar':         {'icono': Icons.local_bar,            'categoria': 'Bebidas',   'label': 'Cerveza'},
    'wine_bar':          {'icono': Icons.wine_bar,             'categoria': 'Bebidas',   'label': 'Vino/Copa'},
    'liquor':            {'icono': Icons.liquor,               'categoria': 'Bebidas',   'label': 'Licor'},
    'coffee':            {'icono': Icons.coffee,               'categoria': 'Bebidas',   'label': 'Cafe'},
    'water_drop':        {'icono': Icons.water_drop,           'categoria': 'Bebidas',   'label': 'Agua'},
    'emoji_food_bev':    {'icono': Icons.emoji_food_beverage,  'categoria': 'Bebidas',   'label': 'Refresco'},
    'local_cafe':        {'icono': Icons.local_cafe,           'categoria': 'Bebidas',   'label': 'Vaso'},
    'icecream':          {'icono': Icons.icecream,             'categoria': 'Bebidas',   'label': 'Hielo'},
    'restaurant':        {'icono': Icons.restaurant,           'categoria': 'Comida',    'label': 'Alitas'},
    'lunch_dining':      {'icono': Icons.lunch_dining,         'categoria': 'Comida',    'label': 'Hamburguesa'},
    'local_pizza':       {'icono': Icons.local_pizza,          'categoria': 'Comida',    'label': 'Pizza'},
    'ramen_dining':      {'icono': Icons.ramen_dining,         'categoria': 'Comida',    'label': 'Nachos'},
    'set_meal':          {'icono': Icons.set_meal,             'categoria': 'Comida',    'label': 'Orden'},
    'fastfood':          {'icono': Icons.fastfood,             'categoria': 'Comida',    'label': 'Comida rapida'},
    'cake':              {'icono': Icons.cake,                 'categoria': 'Comida',    'label': 'Postre'},
    'kitchen':           {'icono': Icons.kitchen,              'categoria': 'Comida',    'label': 'Cocina'},
    'smoking_rooms':     {'icono': Icons.smoking_rooms,        'categoria': 'Servicios', 'label': 'Cigarro'},
    'ac_unit':           {'icono': Icons.ac_unit,              'categoria': 'Servicios', 'label': 'Hielo extra'},
    'cleaning_services': {'icono': Icons.cleaning_services,    'categoria': 'Servicios', 'label': 'Servilletas'},
    'shopping_bag':      {'icono': Icons.shopping_bag,         'categoria': 'Servicios', 'label': 'Empaque'},
    'receipt':           {'icono': Icons.receipt,              'categoria': 'Servicios', 'label': 'Cuenta'},
    'star':              {'icono': Icons.star,                 'categoria': 'Servicios', 'label': 'Especial'},
    'card_giftcard':     {'icono': Icons.card_giftcard,        'categoria': 'Servicios', 'label': 'Regalo'},
    'miscellaneous':     {'icono': Icons.miscellaneous_services,'categoria': 'Servicios','label': 'Otro'},
  };

  static IconData obtener(String clave) {
    final entry = todos[clave];
    if (entry == null) return Icons.sports_bar;
    return entry['icono'] as IconData;
  }

  static Map<String, List<MapEntry<String, Map<String, dynamic>>>> porCategoria() {
    final Map<String, List<MapEntry<String, Map<String, dynamic>>>> grupos = {};
    todos.forEach((clave, data) {
      final cat = data['categoria'] as String;
      grupos.putIfAbsent(cat, () => []);
      grupos[cat]!.add(MapEntry(clave, data));
    });
    return grupos;
  }
}