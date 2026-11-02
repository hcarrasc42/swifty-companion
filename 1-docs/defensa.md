# Defensa

## Las tres herramientas y cómo se relacionan

Escribo el código en **Dart**, con el framework **Flutter**, usando **Android Studio** como entorno.

| Herramienta        | Qué es                   | Qué hace en el proyecto                                                                               |
| ------------------ | ------------------------ | ----------------------------------------------------------------------------------------------------- |
| **Dart**           | Lenguaje de programación | Es en lo que escribo el código (lógica, llamadas a la API, pantallas).                                |
| **Flutter**        | Framework móvil          | Aporta los widgets y el motor gráfico para construir la interfaz de Android e iOS con un solo código. |
| **Android Studio** | IDE                      | Es donde escribo, ejecuto y depuro la app, con el emulador y el SDK de Android.                       |

- **Dart** es el idioma, **Flutter** son las piezas para construir la app y **Android Studio** es el taller donde se trabaja.
- Sin Dart no se puede usar Flutter, porque Flutter está hecho para Dart.
- Android Studio es opcional (también serviría VS Code), pero el subject lo sugiere y está instalado en los PCs de 42.

---

## Por qué Flutter

- **Lo cita el subject:** en Goals aparece "Mobile Frameworks (Flutter)" y Dart.
- **Una sola base de código** para Android e iOS, lo que encaja con el layout "en distintas pantallas y plataformas".
- **Layout flexible de serie:** `Column`, `Row`, `Expanded`, `Flexible`, `LayoutBuilder` y `MediaQuery`.
- **Paquetes para lo que pide el proyecto:** `dio`/`http` para la API, `flutter_dotenv` para el `.env` y `Navigator`/`go_router` para la navegación.
- **Poca fricción en 42:** Android Studio y el SDK de Flutter se instalan sin root.
- **Continuidad** con el resto de la piscina de móvil y demanda en el mercado laboral.

## Por qué no las otras opciones

- **Swift/SwiftUI:** solo iOS y necesita un Mac con Xcode; no se puede compilar en los PCs de 42 con Linux.
- **Kotlin nativo:** solo Android y habría que aprender Jetpack Compose desde cero.
- **Java (Android clásico):** anticuado, con XML y mucho código repetitivo, y Kotlin lo supera.
- **React Native:** añade Node, Metro y dependencias nativas frágiles, sin ventaja frente a Flutter.

---
