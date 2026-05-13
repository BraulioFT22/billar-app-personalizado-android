import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/usuario.dart';
import '../models/producto.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _inicializar();
    return _db!;
  }

  static Future<Database> _inicializar() async {
    final path = join(await getDatabasesPath(), 'billar_manager.db');
    // ⚠️ TEMPORAL — quitar despues del primer arranque exitoso
    await deleteDatabase(path);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _crearTablas,
    );
  }

  static Future<void> _crearTablas(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuarios (
        id     INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        pin    TEXT NOT NULL,
        rol    TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE productos (
        id         TEXT PRIMARY KEY,
        nombre     TEXT NOT NULL,
        precio     REAL NOT NULL,
        esMesa     INTEGER NOT NULL DEFAULT 0,
        iconoClave TEXT NOT NULL DEFAULT 'sports_bar'
      )
    ''');
  }

  static String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  static Future<bool> existeSuperusuario() async {
    final database = await db;
    final result = await database.query('usuarios',
        where: 'rol = ?', whereArgs: ['superusuario']);
    return result.isNotEmpty;
  }

  static Future<void> crearSuperusuario(String nombre, String pin) async {
    final database = await db;
    await database.insert('usuarios',
        {'nombre': nombre, 'pin': hashPin(pin), 'rol': 'superusuario'});
  }

  static Future<Usuario?> login(String pin) async {
    final database = await db;
    final result = await database.query('usuarios',
        where: 'pin = ?', whereArgs: [hashPin(pin)]);
    if (result.isEmpty) return null;
    return Usuario.fromMap(result.first);
  }

  static Future<List<Usuario>> obtenerOperadores() async {
    final database = await db;
    final result = await database.query('usuarios',
        where: 'rol = ?', whereArgs: ['operador']);
    return result.map((m) => Usuario.fromMap(m)).toList();
  }

  static Future<void> crearOperador(String nombre, String pin) async {
    final database = await db;
    await database.insert('usuarios',
        {'nombre': nombre, 'pin': hashPin(pin), 'rol': 'operador'});
  }

  static Future<void> eliminarUsuario(int id) async {
    final database = await db;
    await database.delete('usuarios', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> cambiarPin(int id, String nuevoPin) async {
    final database = await db;
    await database.update('usuarios', {'pin': hashPin(nuevoPin)},
        where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Producto>> obtenerProductos() async {
    final database = await db;
    final result = await database.query('productos');
    return result.map((m) => Producto(
          id: m['id'] as String,
          nombre: m['nombre'] as String,
          precio: (m['precio'] as num).toDouble(),
          esMesa: (m['esMesa'] as int) == 1,
          iconoClave: m['iconoClave'] as String? ?? 'sports_bar',
        )).toList();
  }

  static Future<void> guardarProducto(Producto p) async {
    final database = await db;
    await database.insert(
      'productos',
      {
        'id': p.id,
        'nombre': p.nombre,
        'precio': p.precio,
        'esMesa': p.esMesa ? 1 : 0,
        'iconoClave': p.iconoClave,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> actualizarProducto(Producto p) async {
    final database = await db;
    await database.update(
      'productos',
      {
        'nombre': p.nombre,
        'precio': p.precio,
        'esMesa': p.esMesa ? 1 : 0,
        'iconoClave': p.iconoClave,
      },
      where: 'id = ?',
      whereArgs: [p.id],
    );
  }

  static Future<void> eliminarProducto(String id) async {
    final database = await db;
    await database.delete('productos', where: 'id = ?', whereArgs: [id]);
  }
}