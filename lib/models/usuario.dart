enum RolUsuario { superusuario, operador }

class Usuario {
  final int? id;
  final String nombre;
  final String pin;
  final RolUsuario rol;

  Usuario({
    this.id,
    required this.nombre,
    required this.pin,
    required this.rol,
  });

  bool get esSuperusuario => rol == RolUsuario.superusuario;

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'pin': pin,
        'rol': rol.name,
      };

  factory Usuario.fromMap(Map<String, dynamic> map) => Usuario(
        id: map['id'] as int?,
        nombre: map['nombre'] as String,
        pin: map['pin'] as String,
        rol: RolUsuario.values.firstWhere(
          (r) => r.name == map['rol'],
          orElse: () => RolUsuario.operador,
        ),
      );
}