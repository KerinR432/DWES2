<link rel="stylesheet" href="../css/guia-galactica.css">

<div class="cover">
<p class="serial">CUADERNO DE PRÁCTICAS // DESARROLLO WEB EN ENTORNO SERVIDOR</p>

# D3 · UD3<br>SPRING BOOT

<p class="subtitle">Primeros pasos con Spring Security</p>
<p>Kerin Aguilera</p>
<p class="serial">JAVA 21 · SPRING BOOT 4 · THYMELEAF · SPRING SECURITY · NOVIEMBRE 2026</p>
</div>

<div class="toc">
<p class="toc-title">ÍNDICE DE RUTA</p>
<ol>
<li><a href="#objetivo">Objetivo de la práctica</a></li>
<li><a href="#problema">El problema: proteger una aplicación web</a></li>
<li><a href="#proyecto">Proyecto asociado: `D3-UD3`</a></li>
<li><a href="#plantillas">Plantillas Thymeleaf</a>
  <ul>
    <li><a href="#plantilla-hola">`hola.html` — la zona protegida</a></li>
    <li><a href="#plantilla-casa">`casa.html` — la portada pública</a></li>
    <li><a href="#plantilla-login">`login.html` — el formulario de acceso</a></li>
  </ul>
</li>
<li><a href="#mvcconfig">`MvcConfig`: enrutador de vistas</a></li>
<li><a href="#websecurityconfig">`WebSecurityConfig`: configuración de Spring Security</a>
  <ul>
    <li><a href="#filterchain">`SecurityFilterChain`: qué rutas se protegen</a></li>
    <li><a href="#passwordencoder">`PasswordEncoder`: BCrypt para las contraseñas</a></li>
    <li><a href="#userdetails">`UserDetailsService`: usuarios en memoria</a></li>
    <li><a href="#varios-usuarios">Ampliación: varios usuarios</a></li>
  </ul>
</li>
<li><a href="#funcionamiento">En funcionamiento</a></li>
<li><a href="#jwt">Más allá: JWT (JSON Web Token)</a></li>
<li><a href="#dificultades">Dificultades encontradas y soluciones</a></li>
<li><a href="#resumen">Resumen de conceptos</a></li>
<li><a href="#repaso">Preguntas de repaso</a></li>
<li><a href="#conclusion">Conclusión</a></li>
<li><a href="#recursos">Recursos</a></li>
</ol>
</div>

<a id="objetivo"></a>

## Objetivo de la práctica

En D1-UD3 (sesiones y cookies) aprendimos a mantener el estado entre peticiones guardándolo en el servidor, y en D2-UD3 (autenticación con sesión) montamos a mano un login que guardaba un `Usuario` en la `HttpSession` y protegía las rutas con un `if (user == null)` repetido. Eso funciona, pero **no escala**: cada nueva ruta protegida exige recordar el chequeo, y la seguridad queda dispersa por el controlador.

En esta práctica doy el paso definitivo: delegar la seguridad en **Spring Security**. Aprendo a configurar un `SecurityFilterChain`, a proteger rutas de forma declarativa (`permitAll`, `authenticated`), a usar un formulario de login gestionado por el framework y a codificar las contraseñas con **BCrypt**. El resultado es una aplicación pequeña pero real: una portada pública, una zona protegida y un login con varios usuarios.

El recorrido tiene tres partes. Primero se monta la configuración mínima con un único usuario (`user` / `password`). Después se amplía a varios usuarios (`admin`, `ruvik`) para comprobar que el flujo funciona con distintas credenciales. Por último se recogen los conceptos de **JWT**, que son el siguiente paso natural tras dominar sesiones y Spring Security.

<div class="spec">

| Pieza | Detalle |
|---|---|
| Proyecto | `D3-UD3` (`PROYECTOS/D3-UD3`) |
| Plantillas | `casa.html`, `hola.html`, `login.html` (Thymeleaf) |
| Novedad | `spring-boot-starter-security` · `SecurityFilterChain` · `BCryptPasswordEncoder` |
| Conceptos clave | `@EnableWebSecurity` · `authorizeHttpRequests` · `formLogin` · `logout` · `InMemoryUserDetailsManager` |
| Usuarios de prueba | `user` / `password` · `admin` / `admin` · `ruvik` / `1234` |
| Dependencias extra | `thymeleaf-extras-springsecurity6` |

</div>

<div class="note">

La idea central que me llevo: la seguridad deja de ser código disperso por el controlador y pasa a ser **configuración declarativa**. Spring Security intercepta cada petición antes de que llegue al controlador y decide si el usuario puede pasar.

</div>

<a id="problema"></a>

## El problema: proteger una aplicación web

HTTP trata cada petición como una transacción independiente: el servidor recibe, responde y se olvida. Si una zona es privada, **cada petición** debe demostrar que el usuario está autenticado. Las estrategias posibles son:

1. **Autenticación básica (Basic Auth):** las credenciales viajan en cada petición dentro de la cabecera `Authorization: Basic <base64>`. Sencilla, pero las credenciales se envían siempre.
2. **Formulario + sesión:** el usuario se autentica una vez en `/login`; a partir de ahí una cookie `JSESSIONID` identifica su sesión en el servidor. Es la opción habitual para aplicaciones web con navegador.
3. **Token (JWT):** el servidor emite un token firmado que el cliente envía en cada petición (`Authorization: Bearer …`). Sin estado en el servidor.

En esta práctica uso la opción 2, pero gestionada por Spring Security en lugar de a mano. El framework se encarga de mostrar el formulario, validar las credenciales, crear la sesión y proteger las rutas; yo solo declaro las reglas.

La distinción importante que aprendí es entre **autenticación** (¿quién eres?) y **autorización** (¿qué puedes hacer?). Spring Security configura ambas por separado: la autenticación valida las credenciales; la autorización se expresa con reglas sobre las rutas (`permitAll`, `authenticated`, `hasRole`, etc.).

<a id="proyecto"></a>

## Proyecto asociado: `D3-UD3`

El código de esta práctica vive en `PROYECTOS/D3-UD3`. Es un proyecto Spring Boot 4.2.0 con Thymeleaf, WebMVC y Spring Security. La estructura relevante:

```
D3-UD3/
├── src/main/java/ruvik/d3ud3/
│   ├── D3Ud3Application.java
│   ├── MvcConfig.java
│   └── WebSecurityConfig.java
├── src/main/resources/
│   ├── application.properties
│   └── templates/
│       ├── casa.html
│       ├── hola.html
│       └── login.html
└── build.gradle
```

El `build.gradle` declara Java 21, Spring Boot 4.2.0 y las dependencias de seguridad y Thymeleaf:

```gradle
plugins {
    id 'java'
    id 'org.springframework.boot' version '4.2.0'
    id 'io.spring.dependency-management' version '1.1.7'
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-security'
    implementation 'org.springframework.boot:spring-boot-starter-thymeleaf'
    implementation 'org.springframework.boot:spring-boot-starter-webmvc'
    implementation 'org.thymeleaf.extras:thymeleaf-extras-springsecurity6'
    developmentOnly 'org.springframework.boot:spring-boot-devtools'
    testImplementation 'org.springframework.boot:spring-boot-starter-security-test'
    testImplementation 'org.springframework.boot:spring-boot-starter-thymeleaf-test'
    testImplementation 'org.springframework.boot:spring-boot-starter-webmvc-test'
}
```

`application.properties` solo define el nombre de la aplicación:

```properties
spring.application.name=D3-UD3
```

Para ejecutar el proyecto:

```bash
cd PROYECTOS/D3-UD3
./gradlew bootRun
```

En Windows:

```powershell
cd PROYECTOS\D3-UD3
.\gradlew.bat bootRun
```

Después se abre el navegador en:

```text
http://localhost:8080/
```

La ruta raíz muestra la portada pública; al intentar visitar la zona protegida, Spring Security redirige automáticamente a `/login`.

<a id="plantillas"></a>

## Plantillas Thymeleaf

El proyecto tiene tres plantillas, una por cada zona de la aplicación. He traducido al castellano los textos que venía en inglés en el tutorial original.

<a id="plantilla-hola"></a>

### `hola.html` — la zona protegida

Es la última página que se visualiza si el usuario cumple los requisitos de iniciar sesión. No requiere controlador: `MvcConfig` la sirve directamente.

```html
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:th="https://www.thymeleaf.org">
<head>
    <title>¡HOLA MUNDO!</title>
</head>
<body>
<h1>¡Hola Mundo!</h1>
</body>
</html>
```

<a id="plantilla-casa"></a>

### `casa.html` — la portada pública

Es lo primero que visualiza el usuario al entrar al sitio web. Desde ahí, si pide un saludo y no estaba logado, Spring Security lo manda automáticamente a `/login`.

```html
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:th="https://www.thymeleaf.org">
<head>
    <title>EJEMPLO DE SPRING SECURITY</title>
</head>
<body>
<h1>¡Bienvenido!</h1>

<p>Click <a th:href="@{/hello}">Aqui</a> y te van a saludar </p>
</body>
</html>
```

<a id="plantilla-login"></a>

### `login.html` — el formulario de acceso

Es la parte donde más va a convivir el usuario: aquí se gestiona quién entra y quién no, se le dice si ha fallado en algo y se le ofrece volver a intentarlo. El formulario hace POST a `/login` (que es la URL que Spring Security intercepta) y muestra mensajes según los parámetros de la URL.

```html
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:th="https://www.thymeleaf.org">
<head>
    <title>Spring Security Example </title>
</head>
<body>
<div th:if="${param.error}">
    Nombre de usuario o contraseña es incorrecta.
</div>
<div th:if="${param.logout}">
    You have been logged out.
</div>
<form th:action="@{/login}" method="post">
    <div><label> User Name : <input type="text" name="username"/> </label></div>
    <div><label> Password: <input type="password" name="password"/> </label></div>
    <div><input type="submit" value="Sign In"/></div>
</form>
</body>
</html>
```

Los nombres de los campos (`username`, `password`) son los que Spring Security espera por defecto en un formulario de login. El `th:if="${param.error}"` muestra el mensaje de error cuando Spring Security redirige a `/login?error` tras un intento fallido, y `th:if="${param.logout}"` cuando redirige a `/login?logout` tras cerrar sesión.

<a id="mvcconfig"></a>

## `MvcConfig`: enrutador de vistas

Según lo que he visto en spring.io y Gemini, `MvcConfig` actúa como un encaminador o enrutador: a cada URL le asigna una plantilla, sin necesidad de crear un controlador completo. Me parece muy útil y ameno para páginas que no tienen lógica propia.

```java
package ruvik.d3ud3;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ViewControllerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
class MvcConfig implements WebMvcConfigurer {

    @Override
    public void addViewControllers(ViewControllerRegistry registry) {
        registry.addViewController("/home").setViewName("casa");
        registry.addViewController("/").setViewName("casa");
        registry.addViewController("/hello").setViewName("hola");
        registry.addViewController("/login").setViewName("login");
    }

}
```

Así, `/` y `/home` muestran `casa`, `/hello` muestra `hola` y `/login` muestra `login`. La URL `/login` la gestiona Spring Security para el formulario, pero la vista la sirve este registro. Por eso es importante que `/login` exista aquí: si no, Spring Security no tendría plantilla que mostrar.

<a id="websecurityconfig"></a>

## `WebSecurityConfig`: configuración de Spring Security

Aquí es la zona donde se configura directamente la seguridad de la aplicación. La clase tiene tres `@Bean`: el filtro de seguridad, el codificador de contraseñas y el servicio de usuarios.

```java
package ruvik.d3ud3;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.LogoutConfigurer;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
class WebSecurityConfig {

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http) {
        // @formatter:off
        http
                .authorizeHttpRequests((requests) -> requests
                        .requestMatchers("/", "/home").permitAll()
                        .anyRequest().authenticated()
                )
                .formLogin((form) -> form
                        .loginPage("/login")
                        .permitAll()
                )
                .logout(LogoutConfigurer::permitAll);
        // @formatter:on

        return http.build();
    }

    @Bean
    PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    UserDetailsService userDetailsService(PasswordEncoder encoder) {
        UserDetails user  = User.withUsername("user").password(encoder.encode("password")).roles("USER").build();
        UserDetails admin  = User.withUsername("admin").password(encoder.encode("admin")).roles("ADMIN").build();
        UserDetails ruvik  = User.withUsername("ruvik").password(encoder.encode("1234")).roles("USER").build();
        return new InMemoryUserDetailsManager(user, admin, ruvik);
    }

}
```

<a id="filterchain"></a>

### `SecurityFilterChain`: qué rutas se protegen

El primer `@Bean` es el que define las reglas de acceso:

```java
@Bean
SecurityFilterChain securityFilterChain(HttpSecurity http) {
    http
            .authorizeHttpRequests((requests) -> requests
                    .requestMatchers("/", "/home").permitAll()
                    .anyRequest().authenticated()
            )
            .formLogin((form) -> form
                    .loginPage("/login")
                    .permitAll()
            )
            .logout(LogoutConfigurer::permitAll);
    return http.build();
}
```

Lo que hace, línea a línea:

- `.requestMatchers("/", "/home").permitAll()` — la portada y `/home` son públicas: cualquiera puede entrar sin autenticarse.
- `.anyRequest().authenticated()` — cualquier otra ruta (incluido `/hello`) exige que el usuario esté autenticado. Si no lo está, Spring Security redirige a `/login`.
- `.formLogin((form) -> form.loginPage("/login").permitAll())` — se usa un formulario de login propio (la plantilla `login.html`) en la URL `/login`, y esa URL también es pública (si no, nadie podría ver el formulario).
- `.logout(LogoutConfigurer::permitAll)` — el endpoint de logout (por defecto `/logout`) es accesible para todos los usuarios autenticados.

El `@formatter:off` / `@formatter:on` solo evita que el formateador automático del IDE rompa la cadena fluida en varias líneas; no afecta al funcionamiento.

<a id="passwordencoder"></a>

### `PasswordEncoder`: BCrypt para las contraseñas

```java
@Bean
PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder();
}
```

Crea el codificador que se usará para hashear las contraseñas. BCrypt incluye un *salt* aleatorio dentro del propio hash y es deliberadamente lento, lo que dificulta los ataques por fuerza bruta. Nunca se guarda la contraseña en texto plano.

<a id="userdetails"></a>

### `UserDetailsService`: usuarios en memoria

```java
@Bean
UserDetailsService userDetailsService(PasswordEncoder encoder) {
    UserDetails user  = User.withUsername("user").password(encoder.encode("password")).roles("USER").build();
    UserDetails admin  = User.withUsername("admin").password(encoder.encode("admin")).roles("ADMIN").build();
    UserDetails ruvik  = User.withUsername("ruvik").password(encoder.encode("1234")).roles("USER").build();
    return new InMemoryUserDetailsManager(user, admin, ruvik);
}
```

Aquí se crean los usuarios válidos. Cada uno se construye con `User.withUsername(...)` indicando nombre, contraseña hasheada con BCrypt y rol. El `InMemoryUserDetailsManager` los guarda en memoria: es suficiente para una práctica, pero en producción se sustituiría por una implementación que lea de base de datos.

Los roles (`USER`, `ADMIN`) los asigna Spring Security con el prefijo `ROLE_` automáticamente, de modo que `hasRole("ADMIN")` busca `ROLE_ADMIN`. En esta práctica solo se usan para distinguir usuarios; las reglas de autorización por rol se dejan como ampliación.

<a id="varios-usuarios"></a>

### Ampliación: varios usuarios

Primero monté la configuración con un único usuario para comprobar que el flujo funcionaba:

```java
@Bean
UserDetailsService userDetailsService(PasswordEncoder encoder) {
    String password = encoder.encode("password");
    UserDetails user = User.withUsername("user").password(password).roles("USER").build();
    return new InMemoryUserDetailsManager(user);
}
```

Después la amplié a varios usuarios para poder hacer más pruebas y comprobar que el login funciona con distintas credenciales:

```java
@Bean
UserDetailsService userDetailsService(PasswordEncoder encoder) {
    UserDetails user  = User.withUsername("user").password(encoder.encode("password")).roles("USER").build();
    UserDetails admin  = User.withUsername("admin").password(encoder.encode("admin")).roles("ADMIN").build();
    UserDetails ruvik  = User.withUsername("ruvik").password(encoder.encode("1234")).roles("USER").build();
    return new InMemoryUserDetailsManager(user, admin, ruvik);
}
```

Los tres usuarios de prueba son:

| Usuario | Contraseña | Rol |
|---|---|---|
| `user` | `password` | `USER` |
| `admin` | `admin` | `ADMIN` |
| `ruvik` | `1234` | `USER` |

<a id="funcionamiento"></a>

## En funcionamiento

Vamos a empezar en la página de inicio (la portada pública):

![Portada pública de la aplicación](img%20-%20documents/D3-UD3.1.png)

Vamos a introducir un usuario mal para ver qué errores nos presenta:

![Intento de acceso con credenciales incorrectas](img%20-%20documents/D3-UD3.2.png)
![Mensaje de error en el formulario de login](img%20-%20documents/D3-UD3.3.png)

Ahora metemos el usuario correcto y hace lo siguiente:

![Login con credenciales correctas](img%20-%20documents/D3-UD3.4.png)

Y ahora podemos visitar el sitio de saludos (la zona protegida):

![Zona protegida: ¡Hola Mundo!](img%20-%20documents/D3-UD3.5.png)

Con los varios usuarios, así funciona:

### `admin`

![Login con el usuario admin](img%20-%20documents/D3-UD3.6.png)

Funciona:

![Acceso a la zona protegida con admin](img%20-%20documents/D3-UD3.7.png)

### `ruvik`

![Login con el usuario ruvik](img%20-%20documents/D3-UD3.8.png)

Funciona:

![Acceso a la zona protegida con ruvik](img%20-%20documents/D3-UD3.9.png)

<a id="jwt"></a>

## Más allá: JWT (JSON Web Token)

JWT (cuyas siglas en inglés son *JSON Web Token*) es un estándar definido en el documento RFC 7519. Define un mecanismo para propagar entre dos partes, de forma segura, la identidad de un determinado usuario.

Un **token JWT** es una cadena de texto con tres partes codificadas en Base64, cada una separada por un punto, y literalmente es JSON codificado con su tipo y la información que se manda en el cuerpo. Es un token de tres partes:

- **HEADER** — tipo de token y algoritmo de firma.
- **PAYLOAD** — los datos (claims) del usuario.
- **SIGNATURE** — la firma que verifica que el remitente es quien dice ser y que el mensaje no fue modificado por el camino.

La firma se construye con HMACSHA256 (*Hash-Based Message Authentication Code*), cifrado con el algoritmo SHA de 256 bits. El ciclo de vida empieza cuando el usuario hace un POST enviando usuario y contraseña; se comprueba que son correctos y, de serlo, se genera el token JWT para devolvérselo al usuario. A partir de ahí, la aplicación cliente hace peticiones solicitando recursos y siempre lleva ese token en una cabecera, que sería `Authorization: Bearer <token>`. En el servidor se comprobaría el token mediante la firma, para verificar que es seguro.

Es curioso: en la práctica ya usé algo parecido en Supabase Auth, para poder iniciar sesión con Google y Discord (había que tener un token que le decía a Supabase que preguntara a esos proveedores). También intenté usar Auth0, pero me decanté por Supabase. Programarlo tiene complejidad, pero luego lo hace todo de manera automática y sin más quebraderos de cabeza.

Información extraída de https://openwebinars.net/blog/que-es-json-web-token-y-como-funciona/

Ayuda de Gemini.

<a id="dificultades"></a>

## Dificultades encontradas y soluciones

1. **Inconsistencia entre `/login` y `/login2`.** En una primera versión del `WebSecurityConfig` puse `formLogin().loginPage("/login2")`, pero `MvcConfig` solo mapeaba `/login` a la vista `login`. Al intentar autenticarse, Spring Security redirigía a `/login2`, que no tenía vista asociada y la aplicación fallaba. La solución fue unificar ambas en `/login`: `MvcConfig` sirve la plantilla en `/login` y `WebSecurityConfig` declara `.loginPage("/login")`. Este es el código final que se muestra arriba. Es un detalle pequeño pero importante: la URL del formulario de login debe coincidir con una vista registrada.

2. **Los nombres de los campos del formulario.** Spring Security espera por defecto los parámetros `username` y `password` en el POST a `/login`. Si en `login.html` se usaran otros nombres (por ejemplo `user` o `pass`), la autenticación fallaría silenciosamente. Mantener los nombres por defecto evita tener que configurar `.usernameParameter(...)` y `.passwordParameter(...)`.

3. **`permitAll()` en la portada y en el login.** Al principio olvidé marcar `/` y `/login` como públicas, con lo que la propia página de login quedaba protegida y se producía un bucle de redirecciones (Spring Security redirigía a `/login`, pero `/login` también requería autenticación). Añadir `.requestMatchers("/", "/home").permitAll()` y `.permitAll()` al `formLogin` rompió el bucle.

4. **Usuarios en memoria vs. base de datos.** `InMemoryUserDetailsManager` es cómodo para la práctica, pero los usuarios se pierden al reiniciar y no sirve para producción. Anotado como siguiente paso: sustituirlo por una implementación que lea de una tabla de usuarios con contraseñas BCrypt.

<a id="resumen"></a>

## Resumen de conceptos

### Spring Security

| Elemento | Qué hace |
|---|---|
| `@EnableWebSecurity` | Habilita la configuración de seguridad en la aplicación |
| `SecurityFilterChain` | Define las reglas de protección de rutas |
| `authorizeHttpRequests(...)` | Configura la autorización por ruta |
| `.requestMatchers(...).permitAll()` | Deja esas rutas públicas |
| `.anyRequest().authenticated()` | Exige autenticación para el resto |
| `.formLogin().loginPage("/login")` | Usa un formulario de login propio |
| `.logout(...)` | Habilita el endpoint de cierre de sesión |
| `InMemoryUserDetailsManager` | Guarda los usuarios en memoria |
| `User.withUsername(...)` | Construye un usuario con nombre, contraseña y roles |

### Codificación de contraseñas

| Elemento | Qué hace |
|---|---|
| `BCryptPasswordEncoder` | Genera y verifica hashes BCrypt con salt aleatorio |
| `encoder.encode(texto)` | Genera el hash de una contraseña |
| `encoder.matches(plano, hash)` | Verifica si un texto plano coincide con un hash |

### MVC

| Elemento | Qué hace |
|---|---|
| `@Configuration` | Marca la clase como fuente de beans de configuración |
| `WebMvcConfigurer` | Permite registrar controladores de vista sin controlador completo |
| `addViewControllers(...)` | Asigna una URL a una plantilla directamente |
| `ViewControllerRegistry` | Registro de vistas por URL |

Ideas clave que me llevo de la práctica:

- La seguridad deja de ser código disperso por el controlador y pasa a ser **configuración declarativa** con `SecurityFilterChain`.
- Spring Security intercepta cada petición **antes** de que llegue al controlador y decide si el usuario puede pasar.
- Las contraseñas nunca se guardan en texto plano: se hashean con BCrypt, que incluye el salt dentro del propio hash.
- El formulario de login debe usar los nombres de campo por defecto (`username`, `password`) o configurarlos explícitamente.
- `permitAll()` en la portada y en el login es imprescindible para evitar bucles de redirección.
- `InMemoryUserDetailsManager` sirve para aprender; en producción se sustituye por una fuente de datos real.

<a id="repaso"></a>

## Preguntas de repaso

1. ¿Qué diferencia hay entre autenticación y autorización? *(El problema)*
2. ¿Qué tres estrategias existen para proteger una aplicación web y cuál usa esta práctica? *(El problema)*
3. ¿Qué anotación habilita Spring Security en una aplicación Spring Boot? *(WebSecurityConfig)*
4. ¿Qué hace `requestMatchers("/", "/home").permitAll()` y por qué es necesario? *(SecurityFilterChain)*
5. ¿Qué ocurre si un usuario no autenticado intenta visitar `/hello`? *(SecurityFilterChain)*
6. ¿Por qué se usa BCrypt en lugar de guardar la contraseña en texto plano o con MD5/SHA-1? *(PasswordEncoder)*
7. ¿Qué hace `InMemoryUserDetailsManager` y cuándo conviene sustituirlo? *(UserDetailsService)*
8. ¿Por qué los campos del formulario de login deben llamarse `username` y `password`? *(Plantillas)*
9. ¿Para qué sirven `th:if="${param.error}"` y `th:if="${param.logout}"` en `login.html`? *(Plantillas)*
10. ¿Qué hace `MvcConfig` y por qué se usa en lugar de un controlador completo? *(MvcConfig)*
11. ¿Qué problema causa usar `/login2` en `formLogin` si `MvcConfig` solo registra `/login`? *(Dificultades)*
12. ¿Qué es JWT y de qué tres partes se compone? *(JWT)*
13. ¿Cómo viaja el token JWT en las peticiones posteriores al login? *(JWT)*
14. ¿Qué diferencia hay entre un `SecurityFilterChain` y la protección manual con `if (user == null)` de D2-UD3? *(Resumen)*

<a id="conclusion"></a>

## Conclusión

Esta práctica me hizo tocar con las manos lo que hasta ahora había leído sobre seguridad: que HTTP no recuerda nada y que proteger una aplicación no es escribir `if` por todas partes, sino **declarar reglas** que el framework aplica antes de que la petición llegue al controlador. El cambio es grande en diseño: la seguridad deja de ser código disperso y pasa a ser configuración centralizada en `WebSecurityConfig`.

También me quedo con varios detalles prácticos que al principio pasan desapercibidos pero rompen la aplicación si se ignoran: que la URL del formulario de login debe coincidir con una vista registrada, que los campos deben llamarse `username` y `password` (o configurarse), y que `permitAll()` en la portada y en el login es imprescindible para evitar bucles de redirección.

Con D1-UD3 (sesiones y cookies), D2-UD3 (autenticación a mano con BCrypt) y esta práctica (Spring Security), el recorrido de seguridad de la unidad queda completo: ya sé mantener estado en el servidor, montar un login propio y delegar la seguridad en el framework. El siguiente paso natural, que queda apuntado, es JWT y OAuth2 para autenticación sin estado y delegada.

<a id="recursos"></a>

## Recursos

- [Repositorio del proyecto en GitHub](https://github.com/KerinR432/DWES2)
- [Guía oficial: Securing a Web Application (Spring)](https://spring.io/guides/gs/securing-web/)
- [Documentación de Spring Security](https://docs.spring.io/spring-security/reference/)
- [Documentación de Spring Boot Security](https://docs.spring.io/spring-boot/4.2.0/reference/web/spring-security.html)
- [Documentación de BCryptPasswordEncoder](https://docs.spring.io/spring-security/reference/features/authentication/password-storage.html)
- Apuntes del profesor: `Cookies y Session.pdf`
- Apuntes del profesor: `Sesiones.pdf`
- Bitácora del día 14: autenticación, hash y seguridad básica [[bitacora-dia-cuatro]]
- OpenWebinars: https://openwebinars.net/blog/que-es-json-web-token-y-como-funciona/
- Gemini, como apoyo para interpretar los mensajes de error

<div class="endmark">
FIN DE LA TRANSMISIÓN // D3 · UD3
</div>