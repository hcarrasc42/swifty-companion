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
- **Errores propios (`AuthException`):** red caída, credenciales rechazadas (HTTP distinto de 200) o respuesta sin `access_token` se convierten en una excepción con mensaje claro. La interfaz podrá mostrarlo en el paso 7 sin depender de detalles de `http`. (En el paso 7 se sustituye por `ApiException`, común a toda la app.)
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
- **Errores propios (`UserException`):** 404 (`notFound`), otro código HTTP, red caída y JSON inesperado. La interfaz los mostrará en el paso 7. (En el paso 7 se sustituye por `ApiException`.)
- **Inyección:** `MyApp` recibe el `UserService`, y de ahí pasa a `SearchScreen` y `ProfileScreen`. `ProfileScreen` guarda el `Future` en el estado para no repetir la llamada en cada `build`.
- **Pruebas:** `test/user_service_test.dart` comprueba la URL, la cabecera, el modelo (nulos, porcentaje, cursus principal, proyecto suspendido) y los tres errores. `widget_test.dart` usa un servicio falso. Además se revisó a mano un JSON real de la API (HTTP 200; 404 con un login inexistente).

## Paso 6 — Pantalla de perfil (`lib/screens/profile_screen.dart`, `lib/widgets/`)

**Qué hay:** foto, nombre y login; nivel del cursus con barra; una tarjeta con email, ubicación, wallet y puntos de corrección; las skills con su nivel y porcentaje; y todos los proyectos, incluidos los suspendidos. Si el usuario tiene varios cursus, un selector cambia el nivel, las skills y los proyectos que se muestran.

**Por qué así:**
- **Cumple el subject:** más de 4 datos (login, nombre, email, ubicación, wallet, puntos de corrección, nivel), la foto, skills con nivel y porcentaje, y proyectos aprobados y suspendidos.
- **Widgets separados en `lib/widgets/`:** `ProfileHeader` (cabecera y datos), `LevelBar` y `ProjectTile`. Cada uno hace una cosa y la pantalla solo los compone. `LevelBar` sirve tanto para el nivel del cursus como para cada skill, así el porcentaje se calcula y se dibuja igual en los dos sitios (`levelPercent` en el modelo).
- **Nivel y porcentaje:** 7.65 se muestra como "Nivel 7 · 65 %" con una `LinearProgressIndicator` al 65 %.
- **Proyectos con tres estados:** `validated` true → icono verde y nota; false → icono rojo y nota (suspendido); null → icono gris y el estado traducido ("En curso", "Por corregir"...). Se usa un `switch` sobre `bool?` que obliga a tratar los tres casos.
- **Selector de cursus:** cada proyecto trae `cursus_ids`, así que se filtran los del cursus elegido. Por defecto se muestra el principal (`42cursus`). Sin el filtro, los proyectos de la Piscine y los del cursus saldrían mezclados. El cursus elegido es estado de la pantalla (`_cursusId` + `setState`).
- **Foto con alternativa:** `CircleAvatar` con la foto como `foregroundImage` y la inicial debajo. Si no hay foto, tarda en cargar o falla la descarga, se ve la inicial y la pantalla no se rompe. En la red de 42 el CDN de fotos (`cdn.intra.42.fr`) respondió 403 a cualquier cliente durante las pruebas, así que este caso no es teórico.
- **`ListView`:** el contenido es más alto que la pantalla (un usuario con el cursus avanzado tiene decenas de proyectos), así que tiene que poder desplazarse.
- **`Expanded` en `LevelBar`:** el nombre de la skill ocupa el ancho que sobra y se corta con "..." si es largo, para no empujar el nivel fuera de la pantalla.
- **Ancho máximo de 600:** en pantallas anchas el contenido no se estira de lado a lado. El responsive completo llega en el paso 8.
- **Pruebas:** `test/profile_screen_test.dart` comprueba los datos, el nivel y las skills del cursus principal, los proyectos (con uno suspendido y otro en curso) y el cambio de cursus con el selector. El servicio falso se movió a `test/fake_user_service.dart` para compartirlo entre los tests. Además se probó en Linux con un login real: datos, skills y proyectos correctos, y en la Piscine aparecen los suspendidos en rojo.

## Paso 7 — Gestión de errores (`lib/services/api_exception.dart`, `lib/widgets/error_view.dart`)

**Qué hay:** un único tipo de error, `ApiException`, con un tipo (`ApiError`) y un mensaje para el usuario. Lo usan `AuthService` y `UserService`. En la pantalla de perfil, una vista de error común (`ErrorView`) muestra icono, mensaje y una acción: "Reintentar" si el fallo es pasajero o "Volver" si repetir no cambiaría nada.

**Casos cubiertos:**

| Situación | `ApiError` | Acción |
| --- | --- | --- |
| Login inexistente (404) | `notFound` | Volver |
| Sin red, DNS o conexión cortada | `network` | Reintentar |
| La API no responde en 10 s | `timeout` | Reintentar |
| Faltan credenciales en `.env`, o la API las rechaza (400/401 al pedir el token) | `credentials` | Volver |
| Token rechazado al consultar el usuario (401) | `unauthorized` | Reintentar (se pide token nuevo) |
| Demasiadas peticiones (429; la API de 42 permite 2 por segundo) | `rateLimited` | Reintentar |
| Error del servidor (5xx) | `server` | Reintentar |
| Respuesta que no es JSON (p. ej. HTML de Cloudflare) o sin los campos esperados | `badResponse` | Volver |

**Por qué así:**
- **Un solo tipo de error para toda la API.** Antes `AuthService` lanzaba `AuthException` y `UserService` `UserException`. Un fallo del token llegaba a la pantalla como `AuthException: ...` en crudo, porque la pantalla solo conocía `UserException`. Con `ApiException` la pantalla trata igual cualquier fallo, venga del token o del usuario.
- **El tipo decide la acción (`canRetry`).** Reintentar un 404 o unas credenciales malas daría el mismo resultado; reintentar un corte de red o un 5xx puede funcionar. Los `switch` sobre el `enum` obligan a tratar todos los casos: si se añade un tipo nuevo, el compilador avisa.
- **Mensajes para el usuario, no para el programador.** Un error que no es `ApiException` (un fallo de la propia app) muestra "Ha ocurrido un error inesperado" en vez del detalle técnico.
- **Timeout de 10 s (`sendRequest`).** Sin él, una red que no responde deja la app cargando para siempre. `sendRequest` también convierte cualquier fallo de conexión en `network`, así que los servicios no repiten el mismo `try/catch`.
- **`jsonDecode` protegido.** Si llega HTML o texto, antes la app fallaba con un `FormatException`; ahora es `badResponse`.
- **Credenciales vacías: sin petición.** Si `FT_UID` o `FT_SECRET` están vacíos, se avisa sin llamar a la API.
- **401 al pedir el usuario:** el token guardado se descarta (`AuthService.invalidate()`) y "Reintentar" pide uno nuevo. Repetir la petición sola es el bonus del paso 9.
- **Reintentar:** `ProfileScreen` vuelve a crear el `Future` dentro de `setState`, y el `FutureBuilder` muestra primero la carga (se mira `connectionState` antes que el error, porque al cambiar de `Future` el snapshot conserva el error anterior hasta que termina la nueva petición).
- **Bug encontrado por los tests:** `setState(() => _user = ...)` falla, porque la flecha devuelve el valor de la asignación (un `Future`) y Flutter no admite un callback de `setState` que devuelva un `Future`. Se escribe con llaves.
- **Pruebas:** `auth_service_test.dart` y `user_service_test.dart` cubren cada tipo de error (también el timeout con un tiempo corto inyectado, el HTML y que un 401 obliga a pedir otro token). `profile_screen_test.dart` comprueba la vista de error con "Volver", que "Reintentar" carga el perfil y que un error interno no enseña el detalle. Además se probó en Linux un login inexistente (mensaje, icono y "Volver") y uno válido.

## Paso 8 — Layout responsive (`lib/screens/profile_screen.dart`, `lib/screens/search_screen.dart`)

**Qué hay:** el perfil cambia de layout según el ancho disponible. En un móvil en vertical es una sola columna (máximo 600 px de ancho). A partir de 600 px (móvil en horizontal, tablet, ventana de escritorio ancha) pasa a dos columnas: cabecera, cursus y skills a la izquierda y proyectos a la derecha, cada una con su propio scroll. La búsqueda se puede desplazar y las dos pantallas respetan el notch.

**Por qué así:**
- **`LayoutBuilder` y no `MediaQuery`:** `LayoutBuilder` da el espacio que le queda al widget (sin el `AppBar` ni el `SafeArea`), no el tamaño de toda la pantalla. Se decide con el ancho y no con la orientación, porque una tablet en vertical tiene más ancho que un móvil en horizontal. Así un mismo criterio vale para móvil, tablet y escritorio.
- **Punto de corte en 600:** es el límite que usa Material 3 entre pantalla "compacta" y "mediana". Un móvil en horizontal mide unos 740–900 de ancho y menos de 420 de alto: en una columna, la cabecera ocupaba casi toda la altura y había que desplazarse para ver cualquier dato. Con dos columnas se ven a la vez los datos y los proyectos.
- **`Expanded` en la `Row`:** cada columna se queda la mitad del ancho sobrante. Sin `Expanded`, una `ListView` dentro de una `Row` no tiene ancho máximo y Flutter lanza un error. Cada columna es su propia `ListView`, así los proyectos se desplazan sin mover la cabecera.
- **Ancho máximo (600 en una columna, 1100 en dos):** en una pantalla muy ancha el contenido no se estira de lado a lado, donde las líneas largas cuestan de leer.
- **`SingleChildScrollView` en la búsqueda:** en horizontal, con el teclado abierto, al formulario le quedan unos 100 px de alto. Sin scroll daba overflow (las franjas amarillas y negras). El test lo reproduce: con el código anterior falla con *"A RenderFlex overflowed by 64 pixels"*, y con el nuevo pasa.
- **`SafeArea`:** en horizontal el notch y las esquinas redondeadas quedan a los lados, donde el `AppBar` no protege. `SafeArea` añade ese margen solo en los dispositivos que lo necesitan.
- **Lo que ya era flexible:** `LevelBar` corta los nombres largos con `Expanded` y "...", y `ErrorView` ya tenía scroll y ancho máximo.
- **Pruebas:** en `profile_screen_test.dart`, el perfil a 360×740 (móvil en vertical: una columna), 740×360 (móvil en horizontal: dos) y 1280×800 (tablet: dos). En `widget_test.dart`, la búsqueda a 740×360 con 200 px de teclado. En los tests de widgets, un overflow es un error que hace fallar el test, así que pasar demuestra que no hay overflow con esos tamaños.
