import '../models/usuario.dart';

class SessionService {
  static Usuario? _usuarioActual;

  static Usuario? get usuarioActual => _usuarioActual;
  static bool get estaLogueado => _usuarioActual != null;
  static bool get esSuperusuario => _usuarioActual?.esSuperusuario ?? false;

  static void iniciarSesion(Usuario usuario) => _usuarioActual = usuario;
  static void cerrarSesion() => _usuarioActual = null;
}