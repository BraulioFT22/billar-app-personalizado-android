# 🎱 Billar Manager

Aplicación profesional para la gestión de negocios de billar.
Desarrollada con Flutter para tablets Android.

---

## ✨ Características

- 📊 Dashboard con mesas de billar en tiempo real
- ⏱️ Temporizadores individuales por mesa con persistencia
- 🛒 Catálogo de productos y consumos por mesa
- 💰 Cuenta final desglosada (tiempo + productos consumidos)
- 📈 Resumen de ganancias del día
- 📁 Reportes mensuales descargables en formato .txt
- 🔐 Sistema de usuarios con roles (Superusuario / Operador)
- 🔑 Sistema de licencias por dispositivo
- 🌙 Tema oscuro optimizado para tablets Android

---

## 📱 Requisitos del dispositivo

| Componente | Mínimo | Recomendado |
|---|---|---|
| Sistema operativo | Android 10 | Android 12+ |
| RAM | 3 GB | 6 GB o más |
| Almacenamiento | 16 GB libres | 32 GB libres |
| Pantalla | 10 pulgadas | 10" — 12" |
| Procesador | Octa-core 1.8GHz | Snapdragon 700+ |

> ✅ Probado en Samsung Galaxy Tab S10 FE

---

## 🚀 Instalación para desarrolladores

### Requisitos previos

- [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) 3.x.x stable
- [Android Studio](https://developer.android.com/studio) con Android SDK
- [VS Code](https://code.visualstudio.com/) con extensiones Flutter y Dart
- Tablet Android con Depuración USB activada

### Clonar el repositorio

```bash
git clone https://github.com/TuUsuario/billar-app-base.git
cd billar-app-base
```

### Instalar dependencias

```bash
flutter pub get
```

### Ejecutar en modo desarrollo

```bash
# Verificar entorno
flutter doctor

# Conectar tablet por USB y ejecutar
flutter run
```

> ⚠️ Asegúrate de que `devMode = true` en `lib/main.dart` durante el desarrollo.

---

## 📦 Exportar APK para producción

### Paso 1 — Configurar modo producción

En `lib/main.dart` cambia:
```dart
const bool devMode = false;
```

En `lib/services/licencia_service.dart` cambia:
```dart
static const String _secreto = 'TU_VALOR_SECRETO_UNICO';
```

En `lib/screens/pantalla_generar_licencia.dart` cambia:
```dart
static const String _claveDesarrollador = 'TU_CLAVE_SECRETA';
```

### Paso 2 — Generar el APK

```bash
flutter build apk --release
```

El APK se genera en: build/app/outputs/flutter-apk/app-release.apk

### Paso 3 — Instalar en la tablet del cliente

```bash
# Con la tablet conectada por USB
flutter install
```

O copia el APK manualmente a la tablet y ábrelo.

---

## 🔐 Sistema de Licencias

Cada instalación requiere un código de activación único por dispositivo.

### Como desarrollador — generar una licencia

1. Abre la app en tu tablet de desarrollo
2. En la pantalla de login toca el 🎱 **siete veces**
3. Selecciona **"Generar Licencia"**
4. Ingresa tu clave de desarrollador y el Device ID del cliente
5. Copia el código generado y envíaselo al cliente

### Como cliente — activar la app

1. Instala el APK en tu tablet
2. La app muestra tu Device ID único
3. Envía el Device ID al desarrollador
4. Ingresa el código que te proporcionen
5. ¡Listo! La app queda activada permanentemente

---

## 👥 Roles de usuario

| Función | Superusuario ⭐ | Operador 👤 |
|---|---|---|
| Agregar / eliminar mesas | ✅ | ❌ |
| Gestionar productos y precios | ✅ | ❌ |
| Gestionar usuarios | ✅ | ❌ |
| Ver historial mensual | ✅ | ❌ |
| Descargar reportes | ✅ | ❌ |
| Iniciar / detener mesas | ✅ | ✅ |
| Agregar consumos | ✅ | ✅ |
| Ver resumen del día | ✅ | ✅ |
| Cerrar el día | ✅ | ✅ |

---

## 🗃️ Almacenamiento de datos

| Datos | Tecnología | Ubicación |
|---|---|---|
| Usuarios y productos | SQLite | `billar_manager.db` |
| Estado de mesas | SharedPreferences | `FlutterSharedPreferences.xml` |
| Reportes mensuales | SharedPreferences | `monthly_YYYY_MM` |
| Licencia | SharedPreferences | `licencia_activada` |

---

## 🌿 Estrategia para múltiples clientes

```bash
# La rama main siempre es la versión base limpia
git checkout main

# Para cada cliente nuevo, crear una rama
git checkout -b cliente-nombre-negocio

# Personalizar (logo, nombre, colores)
# y subir la rama del cliente
git push origin cliente-nombre-negocio
```

---

## 🔧 Recuperación de PIN olvidado

En la pantalla de login toca el 🎱 **siete veces** para acceder al
modo desarrollador y resetear el PIN de cualquier usuario.

---

## 📋 Dependencias principales

```yaml
flutter: sdk
shared_preferences: ^2.3.2    # Persistencia clave-valor
sqflite: ^2.3.3+1             # Base de datos SQLite
path_provider: ^2.1.4         # Rutas del sistema de archivos
intl: ^0.19.0                 # Formato de fechas
crypto: ^3.0.3                # Hash de contraseñas SHA-256
vibration: ^2.0.0             # Retroalimentación háptica
share_plus: ^9.0.0            # Compartir archivos
device_info_plus: ^10.1.0     # ID único del dispositivo
```

---

## 📄 Licencia

Este software es de uso comercial privado.
Todos los derechos reservados © 2024.
Desarrollado con ❤️ usando Flutter.