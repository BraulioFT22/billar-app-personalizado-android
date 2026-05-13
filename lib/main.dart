import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/pantalla_activacion.dart';
import 'screens/pantalla_login.dart';
import 'services/licencia_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // ⚠️ MODO DESARROLLO — cambiar devMode a false antes de exportar el APK final
  const bool devMode = true;
  final activada = devMode ? false : await LicenciaService.estaActivada();

  runApp(BillarApp(licenciaActiva: activada));
}

class BillarApp extends StatelessWidget {
  final bool licenciaActiva;
  const BillarApp({super.key, required this.licenciaActiva});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Billar Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      // Si tiene licencia → login | Si no → activación
      home: licenciaActiva
          ? const PantallaLogin()
          : const PantallaActivacion(),
    );
  }
}