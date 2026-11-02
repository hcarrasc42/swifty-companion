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

## Paso 2 — Pantalla de búsqueda (`lib/screens/search_screen.dart`)

**Qué hay:** un campo de texto para el login de 42, un botón "Buscar" y validación del input. Todavía no llama a la API.

**Por qué así:**
- **`StatefulWidget`:** la pantalla guarda dos cosas que cambian o tienen ciclo de vida: el `TextEditingController` (se crea una vez y hay que liberarlo en `dispose`) y el mensaje de error, que al cambiar exige redibujar con `setState`.
- **`TextEditingController`:** es lo que permite leer lo escrito (`_controller.text`) desde el código. Se libera en `dispose()` para no dejar una fuga de memoria.
- **Validación antes de llamar a la API:** se hace `trim()` y `toLowerCase()`, y se rechaza el campo vacío o con caracteres que no existen en un login de 42 (solo `a-z`, `0-9`, `-` y `_`, comprobado con una `RegExp`). Evita peticiones inútiles y da feedback inmediato; el error se muestra con `errorText` del `InputDecoration`.
- **Buscar con el botón o con Enter:** `onSubmitted` y el botón llaman al mismo método (`_search`), para que el comportamiento sea idéntico.
- **Layout:** `Padding` + `Center` + `ConstrainedBox(maxWidth: 480)`. El límite de ancho evita que el campo se estire en pantallas grandes o en horizontal.
- **Estructura:** `main.dart` solo arranca la app; cada pantalla vive en `lib/screens/`, para que el proyecto crezca ordenado.
- **Tests:** `test/widget_test.dart` comprueba que se muestran los errores con el campo vacío y con caracteres inválidos. Sustituye al test del contador de ejemplo.
