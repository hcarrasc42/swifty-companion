# Pruebas

Guía para comprobar la app rápido en la corrección: primero los tests automáticos (un comando) y después las pruebas a mano, ordenadas como los requisitos del subject.

## 1. Tests automáticos

```
flutter analyze                            # debe salir "No issues found!"
flutter test                               # debe salir "All tests passed!" (38)
flutter test --reporter expanded           # lo mismo, con el nombre de cada test
flutter test test/user_service_test.dart   # solo un archivo
```

No usan la red ni el `.env`: la API se sustituye por una falsa (`MockClient`) que responde lo que cada test necesita. Por eso cubren casos difíciles de provocar a mano (un 500, HTML en vez de JSON, un timeout). En los tests de pantallas, un overflow del layout es un error que hace fallar el test.

### `test/auth_service_test.dart` — token OAuth2 (13 tests)

- **pide el token con client_credentials**: la petición va a `/oauth/token` con `grant_type=client_credentials`, el UID y el secret.
- **reutiliza el token mientras no caduca**: dos peticiones, un solo token. No se crea un token por consulta (subject).
- **pide otro token cuando el anterior caduca**: con un reloj falso que avanza, al caducar se pide otro (bonus).
- **maxLifetime acorta la vida del token**: la opción `DEBUG_TOKEN_LIFETIME` funciona (sección 3).
- **debugUseInvalidToken guarda un token sin pedirlo**: la opción `DEBUG_INVALID_TOKEN` funciona (sección 3).
- **credenciales rechazadas lanzan ApiError.credentials**: UID o secret incorrectos.
- **sin credenciales no llama a la API**: con el `.env` vacío se avisa sin hacer ninguna petición.
- **sin red lanza ApiError.network**: fallo de conexión al pedir el token.
- **si la API no responde a tiempo lanza ApiError.timeout**: la app no se queda cargando para siempre.
- **error del servidor lanza ApiError.server**: un 503 al pedir el token.
- **respuesta sin access_token lanza ApiError.badResponse**: JSON sin los campos esperados.
- **respuesta en HTML lanza ApiError.badResponse**: una página de error (p. ej. Cloudflare) en vez de JSON.
- **invalidate descarta el token guardado**: después, `getToken()` pide uno nuevo.

### `test/user_service_test.dart` — consulta del usuario (12 tests)

- **pide /v2/users/:login con el token y construye el modelo**: URL y cabecera `Authorization: Bearer` correctas; el JSON se convierte en el modelo (cursus principal, skills, proyectos aprobados, suspendidos y en curso).
- **404 lanza ApiError.notFound**: login inexistente.
- **401 › pide otro token y repite la petición sin dar error**: bonus. Token rechazado → token nuevo y la búsqueda funciona.
- **401 › si el token nuevo también falla, lanza unauthorized**: un solo reintento, dos peticiones, no un bucle infinito.
- **401 › tras el error, reintentar empieza con un token nuevo**: "Reintentar" no reutiliza el token rechazado.
- **401 › sin 401, el token se reutiliza entre búsquedas**: varias búsquedas con un solo token.
- **429 lanza ApiError.rateLimited**: demasiadas peticiones (la API permite 2 por segundo).
- **5xx lanza ApiError.server**: servidor caído.
- **sin red lanza ApiError.network**: fallo de conexión al pedir el usuario.
- **JSON inesperado lanza ApiError.badResponse**: la respuesta es JSON pero no un usuario.
- **JSON sin campos obligatorios lanza ApiError.badResponse**: falta un campo o tiene otro tipo.
- **un fallo del token llega como ApiException**: un error al pedir el token se muestra igual que cualquier otro.

### `test/profile_screen_test.dart` — pantalla de perfil (9 tests)

- **muestra los datos, el nivel y las skills del cursus principal**: 4+ datos (nombre, email, ubicación, wallet, puntos), nivel y skills con nivel y porcentaje.
- **muestra los proyectos del cursus, suspendidos incluidos**: aprobados, suspendidos (icono rojo) y en curso.
- **login inexistente: mensaje y botón para volver**: un error que no se arregla reintentando muestra "Volver".
- **sin red: reintentar vuelve a cargar el perfil**: un error pasajero muestra "Reintentar" y el perfil carga.
- **un error que no es de la API muestra un mensaje genérico**: no se enseñan detalles técnicos al usuario.
- **móvil en vertical: 1 columna(s) y sin overflow**: a 360×740, una columna y los proyectos se alcanzan con scroll.
- **móvil en horizontal: 2 columna(s) y sin overflow**: a 740×360, dos columnas.
- **tablet: 2 columna(s) y sin overflow**: a 1280×800, dos columnas.
- **cambia de cursus con el selector**: nivel, skills y proyectos cambian al elegir la Piscine.

### `test/widget_test.dart` — búsqueda y navegación (4 tests)

- **muestra error si el login está vacío**: validación del campo.
- **muestra error si el login tiene caracteres inválidos**: solo minúsculas, dígitos, `-` y `_`.
- **móvil en horizontal con el teclado abierto: sin overflow**: el formulario tiene scroll cuando el teclado quita altura.
- **navega al perfil con el login y vuelve atrás**: dos vistas; el login se normaliza (`  Hcarrasc ` → `hcarrasc`) y se vuelve a la primera.

## 2. Pruebas a mano

Lanzar con `flutter run -d linux`. Necesitan el `.env` con `FT_UID` y `FT_SECRET`.

1. **Al menos 2 vistas**
   - Hacer: abrir la app.
   - Esperado: pantalla de búsqueda con un campo y el botón "Buscar".

2. **Validación del login**
   - Hacer: pulsar "Buscar" con el campo vacío; luego escribir `hola mundo!` y buscar.
   - Esperado: "Escribe un login"; luego "Solo letras, números, "-" y "_"".

3. **Datos del usuario**
   - Hacer: buscar un login real (p. ej. el propio).
   - Esperado: foto (o la inicial si no carga), nombre, login, nivel, email, ubicación, wallet y puntos de corrección.

4. **Skills con nivel y porcentaje**
   - Hacer: bajar hasta "Skills".
   - Esperado: cada skill con "Nivel N · X %" y su barra.

5. **Proyectos, suspendidos incluidos**
   - Hacer: bajar hasta "Proyectos" y cambiar a "C Piscine" en el selector.
   - Esperado: verdes (aprobados), rojos (suspendidos) y grises (en curso).

6. **Volver a la primera vista**
   - Hacer: pulsar la flecha del AppBar.
   - Esperado: vuelve a la búsqueda.

7. **Error: login inexistente**
   - Hacer: buscar `zzzzzzzzzz`.
   - Esperado: mensaje, icono de persona tachada y "Volver".

8. **Error: sin red**
   - Hacer: desconectar la red y buscar; reconectar y pulsar "Reintentar".
   - Esperado: icono de wifi tachado y "Reintentar"; al reconectar, carga el perfil.

9. **Error: credenciales**
   - Hacer: cerrar la app, cambiar `FT_SECRET` por uno falso en el `.env` y volver a lanzarla.
   - Esperado: "La API rechazó las credenciales..." y "Volver". Restaurar el secret después.

10. **Layout flexible**
    - Hacer: con un perfil abierto, estrechar y ensanchar la ventana.
    - Esperado: por debajo de 600 px, una columna; por encima, dos. Sin franjas amarillas y negras de overflow.

11. **Un token, no uno por consulta**
    - Hacer: varias búsquedas seguidas, mirando la terminal.
    - Esperado: una sola línea `[auth] token nuevo` para todas.

12. **Bonus: renovar el token**
    - Ver la sección 3.

## 3. Probar la renovación del token (bonus)

El token de 42 dura 2 horas. Para no esperar, hay dos opciones en el `.env` que **solo funcionan en modo debug** (`flutter run`; en una build de release se ignoran). La app escribe en la terminal cuándo pide un token, nunca el token en sí:

```
[auth] token nuevo, válido 7200 s
[users] 401: se pide otro token y se repite
```

Para no abrir el `.env` delante de nadie (se vería el secret), las líneas se añaden y se quitan desde la terminal:

```
echo "DEBUG_TOKEN_LIFETIME=60" >> .env   # añade la línea al final
sed -i '/^DEBUG_/d' .env                 # borra solo las líneas DEBUG_
```

El `.env` se lee al arrancar: después de cambiarlo hay que cerrar la app (`q`) y volver a lanzarla.

### Caducidad (el caso normal)

```
echo "DEBUG_TOKEN_LIFETIME=60" >> .env
flutter run -d linux
```

1. Buscar un login: sale `[auth] token nuevo, válido 60 s`.
2. Buscar otro enseguida: no sale nada nuevo (se reutiliza el token).
3. Esperar más de 30 s (60 s de vida menos el margen de 30 s) y buscar otra vez: sale otra línea `[auth] token nuevo` y la búsqueda funciona sin error.

42 devuelve el mismo token mientras el anterior no ha caducado de verdad, con el tiempo que le queda; por eso, sin esta opción, la duración puede salir menor que 7200. Lo que se comprueba es que la app lo vuelve a pedir sola.

### Token rechazado (401)

```
echo "DEBUG_INVALID_TOKEN=true" >> .env
flutter run -d linux
```

1. Buscar un login. La app empieza con un token falso que la API de 42 rechaza de verdad (401).
2. En la terminal: `[users] 401: se pide otro token y se repite` y después `[auth] token nuevo...`.
3. En pantalla el perfil carga normal, sin ningún error.

### Al terminar

```
sed -i '/^DEBUG_/d' .env
```
