# 🧪 Guía de Pruebas - Alarm & Clock Pro

Esta carpeta contiene la suite completa de pruebas para la aplicación. Se han diseñado para cubrir desde la lógica de negocio hasta la interacción del usuario.

## 📁 Estructura de Pruebas

- **`providers/`**: Pruebas unitarias para los estados de la aplicación.
  - `alarm_provider_test.dart`: Prueba el ciclo de vida de las alarmas (crear, editar, eliminar, activar/desactivar).
- **`widgets/`**: Pruebas de interfaz de usuario.
  - `home_screen_test.dart`: Verifica la navegación entre pestañas.
  - `timer_screen_test.dart`: Prueba la lógica del temporizador y sus controles.
- **`integration/`**: Pruebas que combinan múltiples componentes.
  - `storage_provider_integration_test.dart`: Asegura que las alarmas se guarden y carguen correctamente del almacenamiento local.
- **`services/`**: Pruebas para los servicios individuales (Audio, Notificaciones, etc.).

## 🛠️ Infraestructura de Mocks

Dado que Flutter no permite ejecutar código nativo (Android/iOS) en las pruebas unitarias de escritorio, utilizamos un sistema de **Mocks** centralizado.

### `test_utils.dart`
Este archivo es el corazón de la estabilidad de nuestras pruebas. Contiene la función `setupTestMocks()` que:
1.  Intercepta los canales de comunicación nativos (`MethodChannel`).
2.  Simula respuestas exitosas para servicios como:
    - Reproducción de audio.
    - Programación de alarmas en el sistema.
    - Notificaciones locales.
    - Reconocimiento de voz.
3.  Configura el `JSONMethodCodec` requerido por plugins específicos como `android_alarm_manager_plus`.

## 🚀 Cómo ejecutar las pruebas

### Todas las pruebas
```bash
flutter test
```

### Un archivo específico
```bash
flutter test test/providers/alarm_provider_test.dart
```

### Con ver más detalles (Verbose)
```bash
flutter test -v
```

## 📝 Notas para Desarrolladores
- **Inicialización:** Siempre llama a `setupTestMocks()` en el `setUp` de tus nuevos archivos de prueba.
- **Async:** El `AlarmProvider` tiene un Future `initialization`. Asegúrate de hacer `await provider.initialization;` antes de probar cualquier cambio de estado.
