<link rel="stylesheet" href="../css/guia-galactica.css">

<div class="cover">
<p class="serial">CUADERNO DE PRÁCTICAS // DESARROLLO WEB EN ENTORNO SERVIDOR</p>

# D1 · UD3<br>SPRING BOOT

<p class="subtitle">Spring Security</p>
<p>Kerin Aguilera</p>
<p class="serial">JAVA 21 · SPRING BOOT 4 · THYMELEAF · NOVIEMBRE 2026</p>
</div>

<div class="toc">
<p class="toc-title">ÍNDICE DE RUTA</p>
<ol>
<li><a href="#objetivo">Objetivo de la práctica</a></li>
<li><a href="#problema">El problema de fondo: HTTP no recuerda</a>
<ul>
<li><a href="#sin-estado">Protocolo sin estado</a></li>
<li><a href="#estrategias">Las cuatro estrategias para mantener estado</a></li>
</ul>
</li>
<li><a href="#cookies">Cookies</a>
<ul>
<li><a href="#que-es-cookie">Qué es una cookie</a></li>
<li><a href="#atributos-cookie">Atributos de una cookie</a></li>
<li><a href="#cookie-spring">Cookies en Spring Boot (controlador)</a></li>
<li><a href="#metodos-cookie">Métodos de Cookie más usados</a></li>
</ul>
</li>
<li><a href="#sesiones">Sesiones</a>
<ul>
<li><a href="#que-es-sesion">Qué es una sesión y cómo funciona</a></li>
<li><a href="#jsessionid">JSESSIONID: la cookie que une al usuario con su sesión</a></li>
<li><a href="#httpsession">HttpSession y sus métodos</a></li>
<li><a href="#sesion-spring">Sesiones en Spring Boot (controlador)</a></li>
<li><a href="#configuracion">Configuración y persistencia en base de datos</a></li>
</ul>
</li>
<li><a href="#migracion">De formularios encadenados a sesiones</a>
<ul>
<li><a href="#proyecto-quizz">El proyecto Quizz (formularios encadenados)</a></li>
<li><a href="#fallo">El fallo que me obligó a repensar el flujo</a></li>
<li><a href="#equivalencia">Equivalencia: campo hidden → session.setAttribute</a></li>
</ul>
</li>
<li><a href="#comparativa">Cookies vs sesión</a></li>
<li><a href="#curiosidades">Curiosidades y casos menos usados</a></li>
<li><a href="#suppresswarnings">La anotación @SuppressWarnings</a></li>
<li><a href="#sessionattributes">Método 2: @SessionAttributes</a>
  <ul>
    <li><a href="#sa-que-es">@SessionAttributes: qué es y cómo funciona</a></li>
    <li><a href="#sa-controlador">Controlador con @SessionAttributes (FormsController2)</a></li>
    <li><a href="#sa-errores">Errores típicos y cómo los resolví</a></li>
  </ul>
</li>
<li><a href="#beanscope">Método 3: Bean con scope de sesión (@SessionScope)</a>
  <ul>
    <li><a href="#bean-que-es">Qué es un bean con scope de sesión</a></li>
    <li><a href="#bean-controlador">Controlador con bean de sesión (FormsController3)</a></li>
    <li><a href="#bean-errores">Errores típicos y cómo los resolví</a></li>
  </ul>
</li>
<li><a href="#comparativa3">Comparativa de los tres métodos</a></li>
<li><a href="#resumen">Resumen de conceptos</a></li>
<li><a href="#repaso">Preguntas de repaso</a></li>
<li><a href="#conclusion">Conclusión</a></li>
<li><a href="#recursos">Recursos</a></li>
</ol>
</div>

<a id="objetivo"></a>


# El codigo

He seguido el tutorial, lo que me ha parecido curioso del tutorial es que **"no utiliza controller"** y he visto cosas que nunca he utilizado. 
Pero vayamos por parte, los 3 template son

```text
\template
    casa.html
    hola.html
    login.html
```

y asi se ven, he traducido algunas de las palabras al castellano. 

### Este es el saludo

esta es la ultima pagina en visualizar si él usuario cumple con los requisitos de inciar sesión
```HTML
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


### El Home

Aquí es lo primero que visualiza el usuario al entrar la sitio web, luego de ahí si pide un saludo,sino estaba logiado automaticamente lo manda a Login

```HTML
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

### El login

Este a partado donde mas va comvivir los usuarios, aqui se gestiona quien entra y quien no. Decirle que ha fallado en algo y muchas mas cosas. 

```HTML
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


## EL MvcConfig 

Segun veo el McvConfig, segun lo he visto y no he preguntado aun o buscado en internet. Pero veo como es que es un encaminador o un enrutador, donde ir a este sitio muestra este template. 
Creo que entiendo que seria asi, me parece muy util y ameno.

```JAVA
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


Y segun he visto en spring.oi y gemini, tiene varios usos o metalogias en este caso lo hace para no crear directamente un controller y redirigir a esas URL

## WebSecurityConfig

Creo que aqui es la zona donde, podemos configurar directamente lo que es la configuración de Spring Security, 

el primeor `@Bean`

```JAVA
 @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http)
```
eso creo que es permitir en que sitios los usuarios estan permitidos a ingresar en tipos paginas, por ejemplo en home o login

```JAVA
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
```
Y esto dos `@Bean`

```JAVA
    @Bean
    PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    UserDetailsService userDetailsService(PasswordEncoder encoder) {
        String password = encoder.encode("password");
        UserDetails user = User.withUsername("user").password(password).roles("USER").build();
        return new InMemoryUserDetailsManager(user);
    }
```

lo que hacen es crear un usuario, el unico usuario valido que puede entrar en nuestra web.


# COMO SE VE 

vamos a empezar en la pagina incio

![Código del objeto Quizz](img%20-%20documents/D3-UD3.1.png)

vamos a introducir un usuario mal para ver que errores nos presenta.

![Código del objeto Quizz](img%20-%20documents/D3-UD3.2.png)
![Código del objeto Quizz](img%20-%20documents/D3-UD3.3.png)

Ahora metemos el usuario correcto y hace lo siguiente.

![Código del objeto Quizz](img%20-%20documents/D3-UD3.4.png)

Y ahora podemos visitar el sitio saludos.
![Código del objeto Quizz](img%20-%20documents/D3-UD3.5.png)


# VARIOS USUARIO

Hemos cambiado lo que es le `@Bean` de los usuarios para incrustar mas y poder hacer mas pruebas

```JAVA
    @Bean
    UserDetailsService userDetailsService(PasswordEncoder encoder) {
        UserDetails user  = User.withUsername("user").password(encoder.encode("password")).roles("USER").build();
        UserDetails admin  = User.withUsername("admin").password(encoder.encode("admin")).roles("ADMIN").build();
        UserDetails ruvik  = User.withUsername("ruvik").password(encoder.encode("1234")).roles("USER").build();
        return new InMemoryUserDetailsManager(user, admin, ruvik);
    }

```
Y asi funciona

### admin

![Código del objeto Quizz](img%20-%20documents/D3-UD3.6.png)

funciona
![Código del objeto Quizz](img%20-%20documents/D3-UD3.7.png)

## Ruvik

![Código del objeto Quizz](img%20-%20documents/D3-UD3.8.png)

funciona

![Código del objeto Quizz](img%20-%20documents/D3-UD3.9.png)