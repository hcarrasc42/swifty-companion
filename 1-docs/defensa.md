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

## Paso 3 — Navegación a la pantalla de perfil (`lib/screens/profile_screen.dart`)

**Qué hay:** al pulsar "Buscar" con un login válido se abre una segunda pantalla que muestra ese login, con una flecha para volver atrás.

**Por qué así:**
- **`Navigator.push` con `MaterialPageRoute`:** Flutter gestiona las pantallas como una pila. `push` apila la nueva encima de la de búsqueda; no se destruye la anterior, así que al volver el usuario encuentra el campo como lo dejó.
- **Botón "atrás" gratis:** al haber una ruta debajo en la pila, el `AppBar` dibuja solo la flecha y el gesto/botón de atrás del sistema hace `pop`. No hay que programarlo.
- **El login viaja por el constructor** (`ProfileScreen(login: login)`): es la forma más simple de pasar datos entre pantallas y deja la pantalla de perfil independiente de la de búsqueda.
- **`ProfileScreen` es `StatelessWidget`** por ahora: solo muestra un dato recibido. Pasará a cargar datos de la API en los pasos 5 y 6.
- **Se navega con el login ya normalizado** (sin espacios y en minúsculas), validado en el paso 2.
- **Test:** `test/widget_test.dart` comprueba que se navega con el login normalizado y que `pageBack` vuelve a la búsqueda.

## Paso 4 — Autenticación con la API de 42 (`lib/services/auth_service.dart`)

**Qué hay:** un `AuthService` que obtiene un token de acceso y lo reutiliza mientras sea válido. Las credenciales se leen del `.env` al arrancar (`main.dart`).

**Por qué así:**
- **OAuth2 `client_credentials`:** es el flujo para aplicaciones sin usuario que inicia sesión. La app se identifica con su `client_id` y `client_secret` (`FT_UID` y `FT_SECRET`) mediante un `POST` a `https://api.intra.42.fr/oauth/token` y recibe un token `bearer` que va en la cabecera `Authorization` de las demás peticiones. Con este flujo solo se accede a datos públicos, que es lo que pide el subject.
- **Credenciales en `.env`:** el archivo está en `.gitignore`, así que no llega a GitHub; en el repo solo está `.env.example`, con los nombres de las variables. Se lee con `flutter_dotenv`, y para eso `.env` se declara como *asset* en `pubspec.yaml`.
- **Limitación a conocer:** al ser un asset, el `.env` viaja dentro de la app compilada. En una app real el secret no debería estar en el cliente (iría en un backend); para este proyecto es lo que el subject plantea y se asume.
- **Token guardado y reutilizado:** se guarda en memoria junto con su fecha de caducidad (`expires_in`, 7200 s = 2 h). `getToken()` devuelve el guardado mientras falte más de 30 s para que caduque, y pide uno nuevo si no. Así no se hace una petición de token por cada búsqueda.
- **Errores propios (`AuthException`):** red caída, credenciales rechazadas (HTTP distinto de 200) o respuesta sin `access_token` se convierten en una excepción con mensaje claro. La interfaz podrá mostrarlo en el paso 7 sin depender de detalles de `http`.
- **Cliente HTTP y reloj inyectables:** `AuthService` recibe el `http.Client` y la función de hora, lo que permite probarlo con un cliente simulado y un reloj falso, sin red ni esperas.
- **Pruebas:** `test/auth_service_test.dart` comprueba la petición enviada, la reutilización, la caducidad y los tres errores. Además se verificó a mano contra la API real: respuesta HTTP 200, token `bearer` y `expires_in` de 7200.

**Pregunta probable: ¿por qué no probaste en web?** Chrome puede bloquear las llamadas a la API de 42 por CORS (la política del navegador que exige que el servidor autorice el origen). Esa restricción solo afecta al navegador, no a una app de escritorio o móvil. Por eso la app se prueba en Linux desktop.

## Paso 5 — Llamada a `/v2/users/:login` y modelo (`lib/services/user_service.dart`, `lib/models/user.dart`)

**Qué hay:** un `UserService` que pide el perfil de un login con el token de `AuthService`, y un modelo `User` (con `Cursus`, `Skill` y `ProjectUser`) construido a partir del JSON.

**Por qué así:**
- **Solo se modela lo que se usa.** El JSON de 42 trae más de 40 campos; el modelo guarda login, nombre, email, puntos de corrección, cartera, foto, ubicación, cursus con sus skills y los proyectos. Si la API añade campos, la app no se rompe.
- **Cabecera `Authorization: Bearer <token>`:** el token sale de `auth.getToken()`, así que se reutiliza entre búsquedas y se renueva solo si caduca.
- **Nulos tratados a propósito.** `location` es `null` si el usuario no está en un puesto; `final_mark` y `validated?` son `null` en proyectos sin corregir; `cursus_users` puede venir vacío. Los tipos opcionales (`String?`, `bool?`) lo reflejan para que la pantalla no falle.
- **Skill y porcentaje:** la API da el nivel como decimal (7.65); la parte entera es el nivel y la decimal el porcentaje (65 %), que calcula `Skill.percent`.
- **Cursus principal:** un usuario puede tener varios (`C Piscine`, `42cursus`...). `mainCursus` elige `42cursus` (id 21) y, si no existe, el último.
- **Proyectos suspendidos incluidos:** el modelo conserva todos con su `validated`; el filtrado y el aspecto se deciden en la pantalla (paso 6).
- **Errores propios (`UserException`):** 404 (`notFound`), otro código HTTP, red caída y JSON inesperado. La interfaz los mostrará en el paso 7.
- **Inyección:** `MyApp` recibe el `UserService`, y de ahí pasa a `SearchScreen` y `ProfileScreen`. `ProfileScreen` guarda el `Future` en el estado para no repetir la llamada en cada `build`.
- **Pruebas:** `test/user_service_test.dart` comprueba la URL, la cabecera, el modelo (nulos, porcentaje, cursus principal, proyecto suspendido) y los tres errores. `widget_test.dart` usa un servicio falso. Además se revisó a mano un JSON real de la API (HTTP 200; 404 con un login inexistente).
