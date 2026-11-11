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

## Paso 9 — Bonus: renovar el token (`lib/services/user_service.dart`, `lib/services/auth_service.dart`)

**Qué hay:** el token se renueva solo en los dos casos en que deja de valer, sin que el usuario lo note:

1. **Caduca (lo normal).** El token de 42 dura 2 horas (`expires_in: 7200`). `AuthService` guarda cuándo caduca y, si faltan menos de 30 s, `getToken()` pide uno nuevo antes de usarlo. Esto ya estaba desde el paso 4.
2. **La API lo rechaza antes de tiempo (401).** Por ejemplo, si se regenera el secret en la intra o la API revoca el token. Ahora `fetchUser` descarta el token, pide uno nuevo y repite la petición. Antes de este paso, el usuario veía "La sesión con la API caducó" y tenía que pulsar "Reintentar".

**Por qué así:**
- **Renovar antes de caducar, no después:** si se esperara al 401 para renovar, cada 2 horas una búsqueda fallaría y habría que repetirla. El margen de 30 s evita enviar un token que caduque mientras viaja la petición.
- **No renovar en cada búsqueda:** pedir un token por petición gastaría el límite de la API (2 peticiones por segundo) y duplicaría la espera. El token se reutiliza mientras vale.
- **Un solo reintento:** si el token nuevo también da 401, el problema no es el token (por ejemplo, las credenciales ya no valen) y repetir sin límite sería un bucle infinito. Tras el segundo 401 se muestra el error con "Reintentar", y el token se descarta para que ese reintento empiece con otro.
- **Solo con 401:** un 404, un 429 o un fallo de red no tienen nada que ver con el token, así que se muestran tal cual (paso 7).
- **`_get()` aparte:** la petición (pedir el token + `GET` con la cabecera `Authorization`) está en un método propio, así el reintento la repite sin duplicar código.
- **Por qué en `UserService` y no en `AuthService`:** `AuthService` no sabe si un token funciona; lo sabe quien lo usa y recibe el 401. `AuthService` solo ofrece `invalidate()` para descartarlo.
- **Cómo probarlo a mano:** dos opciones del `.env`, solo en modo debug: `DEBUG_TOKEN_LIFETIME=60` acorta la vida del token para ver la renovación sin esperar 2 horas, y `DEBUG_INVALID_TOKEN=true` empieza con un token falso que 42 rechaza de verdad (401). La terminal escribe cuándo se pide un token, nunca el token. En release (`kDebugMode` falso) se ignoran, así que no cambian la app real. El paso a paso está en `1-docs/pruebas.md`.
- **Lo que hace 42:** si la app pide un token cuando el anterior aún vale, la API devuelve el mismo con el tiempo que le queda (`expires_in` menor que 7200). Por eso se usa `expires_in` y no se supone que siempre son 2 horas.
- **Pruebas:** en `user_service_test.dart`, con una API falsa que responde los códigos que se le pasan y un servicio de token que da `tok1`, `tok2`... Se comprueba que 401 + 200 devuelve el usuario sin error, con dos tokens distintos en las peticiones; que 401 + 401 da `unauthorized` tras solo dos peticiones (sin bucle); que el "Reintentar" posterior usa un tercer token; y que sin 401 el token se reutiliza. Con el código del paso 8, los tres tests del 401 fallan. `auth_service_test.dart` prueba la caducidad con un reloj falso, y también las dos opciones de depuración. Además se probaron las dos contra la API real: con el token falso, 42 responde 401, la app pide otro y carga el perfil; con la vida acortada, el token se reutiliza mientras vale y se pide otro al caducar.

## Arreglo — Foto de perfil con el token (`lib/services/user_service.dart`, `lib/widgets/profile_header.dart`)

**Qué pasaba:** la foto nunca cargaba y se veía siempre la inicial. Se creía que era culpa de la red de 42, pero el CDN de fotos (`cdn.intra.42.fr`) respondía 403 desde cualquier red y cliente (navegador, `curl`, móvil).

**Causa:** el CDN ya no sirve las fotos de forma pública: exige el mismo token de la API en la cabecera `Authorization`. Sin token, 403; con `Authorization: Bearer <token>`, 200. Se comprobó con `curl` y en el emulador Android.

**Qué se cambió:**
- `UserService.imageHeaders()` devuelve `{'Authorization': 'Bearer <token>'}` con el token de `AuthService`. Es el token guardado: **no se pide uno nuevo** (el punto "Token API" de la corrección sigue cumpliéndose).
- `ProfileScreen` carga el usuario y, justo después, las cabeceras (`_load()`, un record `(user, imageHeaders)`). Si pedir las cabeceras fallara, el perfil se muestra igual y la foto se queda en la inicial.
- `ProfileHeader` pasa las cabeceras a `NetworkImage(image, headers: ...)`. La inicial se mantiene debajo como alternativa.
- **Pruebas:** nuevo test en `user_service_test.dart`: tras `fetchUser`, `imageHeaders()` da el mismo token y solo se ha pedido un token. El servicio falso de los tests devuelve cabeceras vacías. Probado en el emulador Android (Pixel 8): la foto se ve, y en los logs aparece un único `token nuevo` en toda la sesión.

## Paso 10 — Simulacro de defensa (preguntas y respuestas)

Preguntas que puede hacer el evaluador, con la idea clave y una frase para responder. Orden: de lo general a lo concreto.

### 1. ¿Cómo se autentica la app con la API de 42?
**Idea:** OAuth2 `client_credentials`. La app envía su `client_id` y `client_secret` (`FT_UID`, `FT_SECRET`) con un `POST` a `/oauth/token`, recibe un token `bearer` de 2 h, lo guarda y lo envía en la cabecera `Authorization` de cada consulta.
> "Mi app se identifica con su `client_id` y su secret mediante OAuth2 `client_credentials`. Recibe un token que dura 2 horas, lo guardo y lo envío en la cabecera `Authorization`. Cuando falta poco para que caduque, pido otro."

### 2. ¿Por qué el secret no está en el código y qué limitación tiene el `.env`?
**Idea:** el secret es privado, así que va en `.env`, que está en `.gitignore`; en el repo solo está `.env.example`. **Limitación real:** el `.env` se declara como *asset*, así que viaja dentro de la app compilada y alguien podría extraerlo. En producción iría en un backend.
> "El secret está en `.env`, que no llega a GitHub. Pero al ser un asset va dentro de la app compilada. En producción iría en un backend; aquí lo asumo porque es lo que plantea el subject."

### 3. ¿Qué pasa si el token caduca o la API lo revoca (401)?
**Idea:** dos casos distintos.
- **Caduca (2 h):** `AuthService` guarda la fecha y pide otro si faltan menos de 30 s. Ya estaba desde el paso 4 (no es el bonus).
- **401 antes de tiempo:** `UserService` descarta el token, pide otro y repite la petición **una sola vez**. Es lo que añade el bonus; sin él, el usuario veía el error y pulsaba "Reintentar".

Se resuelve en sitios distintos porque `AuthService` solo sabe cuándo debería caducar; quien recibe el 401 es `UserService`. Con `client_credentials` no hay *refresh token*: renovar es pedir otro token con las credenciales.
> "Si la API da 401, descarto el token, pido otro y repito la petición. Solo una vez: si el nuevo también da 401, el problema no es el token y repetir sería un bucle infinito."

### 4. ¿Cómo decides el layout y por qué `LayoutBuilder` y no `MediaQuery`?
**Idea:** menos de 600 px, una columna; desde 600 px, dos columnas. `LayoutBuilder` da el espacio real del widget (sin `AppBar` ni `SafeArea`); `MediaQuery` da la pantalla entera. Se decide por ancho y no por orientación porque una tablet en vertical es más ancha que un móvil en horizontal. 600 px es el corte entre pantalla compacta y mediana de **Material 3** (el sistema de diseño de Google, integrado en Flutter).
> "Uso `LayoutBuilder` porque me da el espacio real disponible. Decido por ancho y no por orientación, y el corte de 600 px es el de Material 3."

### 5. ¿Qué pasa si quitas el `Expanded` de la `Row`?
**Idea:** una `Row` da ancho ilimitado a sus hijos y una `ListView` necesita un ancho finito. Sin `Expanded`, Flutter lanza un error de layout. Con `Expanded`, cada columna recibe la mitad del ancho y tiene su propio scroll.
> "Sin `Expanded`, la `ListView` recibe ancho ilimitado y Flutter lanza un error. Con `Expanded`, cada columna recibe la mitad del ancho disponible."

### 6. ¿Por qué "Volver" en unos errores y "Reintentar" en otros?
**Idea:** cada `ApiError` indica si repetir tiene sentido (`canRetry`). 404, credenciales y respuesta rara: repetir daría lo mismo, así que **Volver**. Sin red, timeout, 5xx, 429 y 401: puede funcionar, así que **Reintentar**. "Reintentar" **no reinicia la app**: vuelve a lanzar la misma petición (nuevo `Future` en `setState`).
> "Cada error indica si repetir tiene sentido. Si el login no existe, repetir daría lo mismo; si falla la red, puede funcionar."

### 7. ¿Cuál era la causa real de que la foto no cargara?
**Idea:** el CDN `cdn.intra.42.fr` ya no es público: exige el mismo token de la API en `Authorization`. Sin token da 403; con token, 200. No era el navegador ni la red. Se arregló con `UserService.imageHeaders()` y `NetworkImage(headers: ...)`, **reutilizando el token guardado** (no se pide uno nuevo).
> "El CDN exige el token de la API en la cabecera. Lo comprobé con `curl` y desde el móvil. Lo arreglé enviando esa cabecera con el token que ya tengo."

### 8. ¿Por qué se sospechó de la red de 42 y cómo se descartó?
**Idea:** el 403 apareció en la red de 42, lo que hizo pensar en un bloqueo del campus. Se descartó cambiando una variable cada vez: otra red (casa), otro cliente (navegador, `curl`, móvil) y la petición con el token. Daba 403 en todo salvo con el token.
> "Sospeché de la red de 42, pero daba 403 desde casa y con cualquier cliente. Solo cambió a 200 al añadir el token."

### 9. En Android el contenido se estira al llegar al final del scroll. ¿Es un fallo?
**Idea:** no. Es el *stretch overscroll* nativo de Android 12+. No hay overflow (franjas amarillas y negras), y los tests de widgets lo respaldan: pasan a 360×740, 740×360 y 1280×800.
> "Es el comportamiento nativo de Android al llegar al final de una lista, no un fallo de layout."

### 10. ¿Por qué `ProfileScreen` guarda el `Future` en el estado y no lo crea en `build`?
**Idea:** `build` se ejecuta muchas veces (girar el móvil, teclado, `setState`, cambio de cursus). Crear el `Future` ahí lanzaría una petición nueva cada vez: parpadeo, gasto de red y riesgo de 429 (límite de 2 por segundo). Solo se crea otro cuando el usuario pulsa "Reintentar", dentro de `setState` con llaves (con `=>` falla, porque devuelve un `Future`).
> "Guardo el `Future` en el estado porque `build` se ejecuta en cada redibujado y lanzaría una petición nueva cada vez."

### 11. ¿Cómo conviertes 7.65 en "Nivel 7 · 65 %" y por qué hay campos opcionales?
**Idea:** la parte entera es el nivel y la decimal el porcentaje (`levelPercent`). Los campos `location`, `final_mark` y `validated?` pueden ser `null` (usuario fuera del campus, proyecto sin corregir), y los tipos opcionales obligan a tratarlo. `validated` es `bool?`, con tres estados: aprobado (verde), suspendido (rojo) y en curso (gris).
> "La parte entera es el nivel y la decimal el porcentaje. Los campos pueden ser `null`, y con tipos opcionales la pantalla está obligada a tratarlos."

### 12. ¿Qué cambiarías en producción?
**Idea:** un **backend intermedio**. El secret viviría solo en el servidor (variables de entorno o gestor de secretos), que pediría el token y llamaría a 42; la app solo hablaría con él. Además, caché de respuestas para respetar el límite de 2 peticiones por segundo. Una base de datos solo haría falta para datos propios (usuarios, historial), no para guardar el secret.
> "Lo primero sería mover el secret a un backend, porque ahora viaja dentro de la app. La app hablaría con mi servidor y este con 42."

### 13. ¿Por qué añadiste el permiso `INTERNET` si en debug ya funcionaba?
**Idea:** Android solo deja usar la red a las apps que declaran `INTERNET` en su `AndroidManifest.xml`. Flutter lo pone por su cuenta en los manifiestos de `debug/` y `profile/`, porque los necesita para conectarse con la app mientras desarrollas, pero no en `main/`, que es el que usa la versión de release. Sin él, `flutter run` funcionaba, pero con `flutter run --release` o la APK de `flutter build apk` la app abría y cada búsqueda daba "Sin conexión con la API de 42". El manifiesto lo genera `flutter create`, pero es la configuración de la app y los permisos los declara el desarrollador, como indica la documentación de Flutter.
> "En debug Flutter añade el permiso de Internet por su cuenta, pero en release no. Mi app necesita la red para llamar a la API de 42, así que lo declaro en el manifiesto principal."

### Para repasar más
Las que más cuestan: **3** (caducidad frente a 401, y qué añade el bonus), **4 y 5** (layout y `Expanded`) y **10** (`Future` en `build`).
