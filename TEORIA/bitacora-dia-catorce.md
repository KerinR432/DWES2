# DÍA CATORCE — AUTENTICACIÓN, HASH Y SEGURIDAD BÁSICA

## Índice

1. [Resumen de la sesión](#resumen-de-la-sesión)
2. [Autenticación vs. autorización](#autenticación-vs-autorización)
3. [El problema: HTTP sin estado y el login](#el-problema-http-sin-estado-y-el-login)
4. [Hash y salt](#hash-y-salt)
5. [Autenticación básica (Basic Auth)](#autenticación-básica-basic-auth)
6. [Spring Security: configuración en Java](#spring-security-configuración-en-java)
7. [Codificación de contraseñas con BCrypt](#codificación-de-contraseñas-con-bcrypt)
8. [Roles y autorización de rutas](#roles-y-autorización-de-rutas)
9. [Personalizar la respuesta de error (401)](#personalizar-la-respuesta-de-error-401)
10. [Pruebas con `curl`](#pruebas-con-curl)
11. [Buenas prácticas de seguridad](#buenas-prácticas-de-seguridad)
12. [Más allá: JWT y OAuth2](#más-allá-jwt-y-oauth2)
13. [Comparación con las bitácoras anteriores](#comparación-con-las-bitácoras-anteriores)
14. [Chuleta de código](#chuleta-de-código)
15. [Pendientes y preguntas](#pendientes-y-preguntas)

---

## Resumen de la sesión

El día 14 abrimos el bloque de **seguridad**. Partimos de la idea que ya manejamos desde el día 13: HTTP es un protocolo **sin estado**, así que el servidor no sabe por sí solo quién eres en cada petición. Para una zona privada necesitamos **autenticar** al usuario y recordar que ya lo hicimos.

La libreta original de este día era muy corta y decía, literalmente:

> «La primera práctica va a ser aplicar lo de la práctica D1-UD3 pero de otra forma distinta.»
>
> «USUARIO -------------- SERVIDOR — autentificarse»
>
> «La zona privada son distintas páginas y si el usuario no se autentica pues mostramos cada rato usuario/contraseña.»
>
> «HASH: es una función que a partir de una información genera una firma compacta de esa información. Algoritmos de HASH conocidos son MD5, SHA-512… una función matemática que no se puede reconstruir a lo anterior.»

La intuición es correcta, pero conviene precisarla:

- No basta con «mostrar cada rato usuario/contraseña»: eso es exactamente lo que hace la **autenticación básica** (Basic Auth), que envía las credenciales **en cada petición** codificadas en Base64.
- Un **hash** no es «irreversible por magia»: es una función de un solo sentido (no tiene inversa matemática), pero eso no evita los **ataques por diccionario o por tablas arcoíris** si no se usa **salt**.
- La seguridad real no se implementa a mano: en Spring Boot se delega en **Spring Security**, que ya resuelve autenticación, autorización, codificación de contraseñas y protección de rutas.

Lo que vimos:

- Diferencia entre **autenticación** (quién eres) y **autorización** (qué puedes hacer).
- Por qué HTTP sin estado obliga a enviar las credenciales en cada petición si usamos Basic Auth.
- Qué es un **hash**, qué es un **salt** y por qué BCrypt es la opción recomendada.
- Cómo configurar **Spring Security** con `SecurityFilterChain` y usuarios en memoria.
- Cómo codificar contraseñas con **BCrypt**.
- Cómo proteger rutas por **roles**.
- Cómo personalizar la respuesta **401**.
- Cómo probar todo con **`curl`**.
- Buenas prácticas: HTTPS, no guardar contraseñas en texto plano, auditoría.
- Hacia dónde seguir: **JWT** y **OAuth2**.

> 💡 **Idea clave del día:** la autenticación no es «guardar una contraseña», es **verificar una identidad**. La contraseña nunca se guarda tal cual: se guarda su **hash con salt**, y se compara hashes, no textos.

---

## Autenticación vs. autorización

Son dos conceptos distintos y conviene no mezclarlos:

| Concepto | Pregunta que responde | Ejemplo |
| --- | --- | --- |
| **Autenticación** | ¿Quién eres? | Introducir usuario y contraseña |
| **Autorización** | ¿Qué puedes hacer? | Un usuario normal no puede borrar usuarios |

- **Autenticación** verifica la identidad: comprueba que el usuario es quien dice ser.
- **Autorización** decide los permisos: una vez autenticado, ¿a qué recursos tiene acceso?

En Spring Security se configuran por separado: la autenticación valida las credenciales; la autorización se expresa con reglas sobre las rutas (`permitAll`, `authenticated`, `hasRole`, etc.).

---

## El problema: HTTP sin estado y el login

HTTP trata cada petición como independiente. Si una zona es privada, **cada petición** debe demostrar que el usuario está autenticado.

Hay varias formas de hacerlo:

| Mecanismo | Cómo viajan las credenciales | Estado en servidor |
| --- | --- | --- |
| Basic Auth | En cada petición (Base64) | Sesión opcional |
| Formulario + sesión | Solo en el login; luego cookie `JSESSIONID` | Sesión en servidor |
| Token (JWT) | En cada petición (`Authorization: Bearer …`) | Sin estado en servidor |

Basic Auth es el más sencillo y el que se usa en el PDF de introducción a Spring Security: el navegador (o `curl`) envía `Authorization: Basic <base64(usuario:contraseña)>` en **cada** solicitud.

> ⚠️ Base64 **no es cifrado**: cualquiera que intercepte la petición puede decodificarla. Por eso Basic Auth solo es aceptable con **HTTPS**.

---

## Hash y salt

### Qué es un hash

Un **hash** es una función matemática que transforma una entrada de tamaño arbitrario en una salida de tamaño fijo (la «firma» o «resumen»). Propiedades clave:

- **Determinista**: la misma entrada produce siempre la misma salida.
- **Unidireccional**: no se puede reconstruir la entrada a partir de la salida.
- **Sensible a cambios**: cambiar un bit de la entrada cambia por completo la salida.

Algoritmos conocidos: MD5, SHA-1, SHA-256, SHA-512. Para contraseñas **no** se usan MD5 ni SHA-1 (son rápidos y vulnerables a tablas arcoíris); se usan funciones lentas y con salt como **BCrypt**.

### Qué es el salt

El **salt** es una cadena aleatoria que se concatena a la contraseña antes de calcular el hash. Su función es que dos usuarios con la misma contraseña obtengan hashes distintos, y que un atacante no pueda usar **tablas precalculadas** (rainbow tables).

El ejemplo de la libreta, explicado:

```text
usuario = feliz
contraseña = 1234
salt generado por el sistema = 5j3h

hash guardado = BCrypt("1234" + "5j3h")  →  $2a$10$... (incluye el salt dentro)
```

Al autenticarse:

```text
usuario = feliz
contraseña introducida = 1234
salt recuperado de la BD = 5j3h

hash calculado = BCrypt("1234" + "5j3h")
se compara con el hash guardado → si coincide, entra
```

> 💡 El salt **no es secreto**: se guarda junto al hash. Su valor está en ser **único por usuario**, no en ocultarse.

### Tabla resumen

| Algoritmo | Uso recomendado | Velocidad | Seguro para contraseñas |
| --- | --- | --- | --- |
| MD5 | Checksums, no seguridad | Muy rápido | ❌ |
| SHA-1 | Checksums legacy | Rápido | ❌ |
| SHA-256 / SHA-512 | Integridad de datos | Rápido | ❌ (sin salt y KDF) |
| BCrypt | Contraseñas | Lento (configurable) | ✅ |
| Argon2 | Contraseñas (moderno) | Lento | ✅ |

---

## Autenticación básica (Basic Auth)

En Basic Auth las credenciales se envían en cada petición dentro de la cabecera `Authorization`:

```http
GET /zona-privada HTTP/1.1
Host: localhost:8080
Authorization: Basic dXNlcjE6dXNlcjFQYXNz
```

El valor tras `Basic ` es `usuario:contraseña` codificado en Base64. El servidor lo decodifica, busca el usuario y compara la contraseña (en realidad, su hash).

Ventajas:
- Muy sencillo de implementar.
- Soportado por todos los navegadores y clientes HTTP.

Inconvenientes:
- Las credenciales viajan en **cada** petición.
- Base64 no es cifrado: hace falta **HTTPS**.
- No hay «logout» real: el navegador recuerda las credenciales hasta que se cierra.

---

## Spring Security: configuración en Java

Para usar Spring Security hay que añadir la dependencia:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
```

La clase de configuración es el «corazón» de la seguridad:

```java
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/securityNone").permitAll()
                .anyRequest().authenticated()
            )
            .httpBasic(); // habilita autenticación básica
        return http.build();
    }

    @Bean
    public UserDetailsService users() {
        UserDetails user = User.builder()
            .username("user1")
            .password("{noop}user1Pass") // {noop} = sin codificar (solo desarrollo)
            .roles("USER")
            .build();
        return new InMemoryUserDetailsManager(user);
    }
}
```

Puntos clave:
- `@EnableWebSecurity` habilita la configuración de seguridad.
- `SecurityFilterChain` define qué rutas se protegen.
- `requestMatchers("/securityNone").permitAll()` deja esa ruta pública.
- `anyRequest().authenticated()` exige autenticación para el resto.
- Los usuarios se definen en memoria con `InMemoryUserDetailsManager` (para desarrollo; en producción van en BD).

---

## Codificación de contraseñas con BCrypt

Guardar contraseñas en texto plano es un error grave. Spring Security ofrece `BCryptPasswordEncoder`:

```java
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

@Bean
public PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder();
}
```

Uso:

```java
// Al registrar un usuario
String hash = passwordEncoder.encode("1234");
// hash ≈ "$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy"

// Al autenticar
boolean ok = passwordEncoder.matches("1234", hash); // true
```

BCrypt incorpora el salt dentro del propio hash y es **lento a propósito** (coste configurable), lo que dificulta los ataques por fuerza bruta.

En la configuración de usuarios, si se usa BCrypt, la contraseña se guarda ya codificada:

```java
UserDetails user = User.builder()
    .username("user1")
    .password(passwordEncoder.encode("user1Pass"))
    .roles("USER")
    .build();
```

> ⚠️ Si se usa `{noop}` (sin codificar) es solo para pruebas. En producción siempre BCrypt (o Argon2).

---

## Roles y autorización de rutas

Los roles permiten diferenciar permisos:

```java
http.authorizeHttpRequests(auth -> auth
    .requestMatchers("/admin/**").hasRole("ADMIN")
    .requestMatchers("/user/**").hasAnyRole("USER", "ADMIN")
    .anyRequest().authenticated()
);
```

Los roles se asignan al crear el usuario:

```java
UserDetails admin = User.builder()
    .username("admin")
    .password(passwordEncoder.encode("adminPass"))
    .roles("ADMIN", "USER")
    .build();

UserDetails user = User.builder()
    .username("user1")
    .password(passwordEncoder.encode("user1Pass"))
    .roles("USER")
    .build();
```

Spring Security añade automáticamente el prefijo `ROLE_` a los roles, por lo que `hasRole("ADMIN")` busca `ROLE_ADMIN`.

---

## Personalizar la respuesta de error (401)

Por defecto, Spring Security devuelve un `401 Unauthorized` genérico. Se puede personalizar con un `BasicAuthenticationEntryPoint`:

```java
import org.springframework.security.web.authentication.www.BasicAuthenticationEntryPoint;

public class CustomEntryPoint extends BasicAuthenticationEntryPoint {
    @Override
    public void commence(HttpServletRequest request, HttpServletResponse response,
                         AuthenticationException authException) throws IOException {
        response.addHeader("WWW-Authenticate", "Basic realm=\"" + getRealmName() + "\"");
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.getWriter().println("Error 401: " + authException.getMessage());
    }

    @Override
    public void afterPropertiesSet() {
        setRealmName("MiApp");
        super.afterPropertiesSet();
    }
}
```

Se registra en la configuración:

```java
http.httpBasic(basic -> basic.authenticationEntryPoint(new CustomEntryPoint()));
```

---

## Pruebas con `curl`

Sin credenciales (debe devolver 401):

```bash
curl -i http://localhost:8080/zona-privada
```

Respuesta esperada:

```text
HTTP/1.1 401 Unauthorized
```

Con credenciales correctas:

```bash
curl -i -u user1:user1Pass http://localhost:8080/zona-privada
```

Respuesta esperada: `200 OK` con el contenido protegido.

Ruta pública (no requiere credenciales):

```bash
curl -i http://localhost:8080/securityNone
```

---

## Buenas prácticas de seguridad

- **Usar HTTPS** en producción para proteger las credenciales en tránsito.
- **No guardar contraseñas en texto plano**: usar BCrypt o Argon2.
- **No reutilizar salts**: uno por usuario.
- **Mantener la aplicación y las dependencias actualizadas**.
- **Implementar registro de auditoría** (quién accedió, cuándo, desde dónde).
- **No exponer información sensible** en los mensajes de error.
- **Cerrar sesiones** cuando sea necesario (`invalidate()`).

> ⚠️ Basic Auth envía las credenciales en cada petición. Para aplicaciones web con navegador, suele preferirse un **formulario de login + sesión** o **tokens (JWT)**.

---

## Más allá: JWT y OAuth2

- **JWT (JSON Web Token)**: token firmado que contiene la información del usuario. Permite autenticación **sin estado** en el servidor.
- **OAuth2**: protocolo de autorización delegada («Iniciar sesión con Google/GitHub»).
- **Spring Security OAuth**: módulo de Spring para implementar OAuth2/OpenID Connect.

Estos temas son el siguiente paso natural tras dominar Basic Auth y sesiones.

---

## Comparación con las bitácoras anteriores

- **Día 13 (cookies y sesiones)**: vimos `JSESSIONID`, `HttpSession` y cómo guardar estado en el servidor. La autenticación básica se apoya en esas mismas ideas (la sesión puede recordar que el usuario ya se autenticó).
- **Día 12 (redirect y PRG)**: tras un login correcto suele hacerse `redirect` para evitar reenviar el formulario.
- **Día 11 (Lombok y `@ModelAttribute`)**: los objetos de usuario/credenciales se enlazan igual que cualquier otro POJO.
- **Día 7 (HTTP sin estado)**: la autenticación existe precisamente porque HTTP no recuerda.

---

## Chuleta de código

### Dependencia

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
```

### Configuración mínima

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http.authorizeHttpRequests(auth -> auth
                .requestMatchers("/publico").permitAll()
                .anyRequest().authenticated())
            .httpBasic();
        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
```

### Usuario en memoria con BCrypt

```java
@Bean
public UserDetailsService users(PasswordEncoder encoder) {
    UserDetails user = User.builder()
        .username("user1")
        .password(encoder.encode("user1Pass"))
        .roles("USER")
        .build();
    return new InMemoryUserDetailsManager(user);
}
```

### Codificar / verificar contraseña

```java
String hash = encoder.encode("1234");
boolean ok = encoder.matches("1234", hash);
```

---

## Pendientes y preguntas

- ¿Cómo integrar Spring Security con una base de datos real (tabla de usuarios)?
- ¿Cómo combinar Basic Auth con un formulario de login HTML?
- ¿Cuándo conviene usar JWT en lugar de sesión?
- ¿Cómo implementar «recordarme» (remember-me) con cookies?
- ¿Cómo proteger contra CSRF en formularios web?

<div class="endmark">
FIN DE LA TRANSMISIÓN // DÍA CATORCE
</div>