<link rel="stylesheet" href="../css/guia-galactica.css">

<div class="cover">
<p class="serial">CUADERNO DE PRÁCTICAS // DESARROLLO WEB EN ENTORNO SERVIDOR</p>

# D4 · UD2<br>SPRING BOOT

<p class="subtitle">Parámetros HTTP e internacionalización</p>
<p>Kerin Aguilera</p>
<p class="serial">JAVA 21 · SPRING BOOT · THYMELEAF · OCTUBRE 2026</p>
</div>

<div class="toc">
<p class="toc-title">ÍNDICE DE RUTA</p>
<ol>
<li><a href="#objetivo">Objetivo y contenidos</a></li>
<li><a href="#procesamiento-http">Procesamiento de datos en HTTP</a>
<ul>
<li><a href="#post">Envío mediante POST</a></li>
<li><a href="#error-405">Un error real: el 405 del formulario GET</a></li>
<li><a href="#get">Envío mediante GET</a></li>
</ul>
</li>
<li><a href="#query-string">Codificación y Query String</a>
<ul>
<li><a href="#codificar">El controlador que codifica</a></li>
<li><a href="#round-trip">El viaje de ida y vuelta de un parámetro</a></li>
</ul>
</li>
<li><a href="#internacionalizacion">Internacionalización (i18n)</a>
<ul>
<li><a href="#recorrido-i18n">Cómo decide la aplicación el idioma</a></li>
<li><a href="#mensajes">Los archivos de mensajes</a></li>
<li><a href="#alternativa-a">Alternativa A · Cambiar el idioma con ?lang=</a></li>
<li><a href="#alternativa-b">Alternativa B · La cabecera Accept-Language</a></li>
<li><a href="#plantilla-i18n">La plantilla: la sintaxis #{...}</a></li>
</ul>
</li>
<li><a href="#resumen">Resumen de conceptos</a></li>
<li><a href="#repaso">Preguntas de repaso</a></li>
<li><a href="#conclusion">Conclusiones</a></li>
<li><a href="#recursos">Recursos</a></li>
</ol>
</div>

<a id="objetivo"></a>

## Objetivo y contenidos

Última práctica de la unidad, y vuelve al lado del protocolo. En D2 y D3 me centré en formularios, objetos y plantillas; aquí bajo a mirar **cómo viajan realmente los datos por HTTP**: dónde van en un POST, dónde en un GET, por qué una URL no admite cualquier carácter y cómo una misma aplicación puede responder en varios idiomas.

El trabajo tiene dos partes. Primero comparo los métodos **POST** y **GET** con el mismo formulario, me encuentro (y arreglo) un error de mapeo 405, y observo cómo se codifican los parámetros de una URL. Después configuro la **internacionalización** y compruebo la respuesta en español e inglés desde Bruno.

<div class="spec">

| Pieza | Detalle |
|---|---|
| Proyecto | `D4-UD2` |
| Controladores | `controllador` (`/codificacion/...`) · `I18Controller` (`/i18n`) |
| Novedades | `URLEncoder` · `LocaleResolver` · `MessageSource` · archivos `.properties` |
| Cliente de pruebas | Bruno, para inspeccionar cabeceras y cuerpos |

</div>

<a id="procesamiento-http"></a>

## 1. Procesamiento de datos en HTTP

<a id="post"></a>

### Envío mediante POST

Para comprobar qué datos envía un formulario utilizo **Bruno** y reviso la petición recibida. En una petición POST, los datos del formulario viajan en el **cuerpo de la petición**, no como parte de la dirección URL.

En la primera captura se muestra el envío de un valor:

![Petición POST con el valor enviado desde el formulario](img%20-%20documents/D4-UD2.2.png)

También compruebo la cabecera `Content-Type`, que indica el tipo de contenido enviado (en un formulario HTML normal, `application/x-www-form-urlencoded`):

![Cabecera Content-Type de la petición](img%20-%20documents/D4-UD2.1.png)

Este es el controlador que recibe el parámetro `nombre` y lo añade al modelo:

```java
package ruvik.d4ud2.controllador;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
@RequestMapping("/codificacion")
public class controllador {

    @GetMapping
    public String mostrarFormulario() {
        return "formulario";
    }

    @PostMapping("/procesar")
    public String procesar(@RequestParam String nombre, Model modelo) {
        modelo.addAttribute("nombre", nombre);
        return "resultado";
    }
}
```

Un detalle nuevo aquí: la anotación **`@RequestMapping("/codificacion")`** en la clase. Todas las rutas de sus métodos se interpretan **relativas** a ese prefijo, así el controlador agrupa bajo `/codificacion` su formulario (`GET /codificacion`), su versión POST (`/procesar`) y su versión GET (`/procesar2`).

<a id="error-405"></a>

### Un error real: el 405 del formulario GET

Al probar el formulario con el método GET, recibí un error. El controlador tenía estas dos rutas:

```java
@PostMapping("/procesar")
public String procesar(@RequestParam String nombre, Model modelo) {
    modelo.addAttribute("nombre", nombre);
    return "resultado";
}

@GetMapping("/procesar2")
public String procesadoGet(@RequestParam String nombre, Model modelo) {
    prepararModelo("GET", nombre, modelo);
    return "resultado";
}
```

Sin embargo, el formulario enviaba la petición GET a `/codificacion/procesar`:

```html
<form method="GET" action="/codificacion/procesar">
```

La ruta `/codificacion/procesar` solo acepta POST; la ruta GET está definida en `/codificacion/procesar2`. Por eso Spring responde con el error **405 Method Not Allowed**: la URL existe, pero no para ese método. Es un error distinto del 404 (la ruta no existe) y del 400 (petición mal formada): el servidor entiende la petición y se niega a tramitarla por el método empleado. Para corregirlo, el `action` del formulario debe coincidir con la ruta GET:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>FORMULARIO DE DATOS</title>
</head>
<body>
    <form method="GET" action="/codificacion/procesar2" enctype="multipart/form-data">
        <input type="text" name="nombre" id="nombre" placeholder="Nombre">
    </form>
</body>
</html>
```

La captura muestra el error antes de aplicar la corrección:

![Error 405 al enviar una petición GET a una ruta configurada para POST](img%20-%20documents/D4-UD2.3.png)

<div class="note">

Dos detalles de este formulario final que me llamaron la atención. No lleva botón de envío: el formulario se puede mandar pulsando Enter dentro del campo, y en las pruebas también escribí la URL directamente en la barra de direcciones. Y el atributo `enctype="multipart/form-data"` es en realidad irrelevante aquí: ese tipo de codificación existe para **subir archivos con POST**; en un GET los datos van en la URL y el atributo no tiene efecto. Lo dejo anotado para no confundirlo en el futuro.

</div>

<a id="get"></a>

### Envío mediante GET

Con GET, los parámetros se añaden a la URL como una **cadena de consulta** (*query string*). Por eso pueden verse en la barra de direcciones. En la captura se aprecia la URL generada al enviar el formulario:

![Parámetro enviado como parte de la URL](img%20-%20documents/D4-UD2.4.png)

También probé a escribir directamente una dirección con caracteres especiales. La petición no se procesó correctamente porque esos caracteres deben **codificarse** para formar una URL válida:

![Error al introducir caracteres especiales sin codificar en la URL](img%20-%20documents/D4-UD2.6.png)

GET resulta práctico para búsquedas y filtros que se puedan compartir mediante un enlace. Como sus parámetros quedan visibles en la URL (y quedan guardados en el historial del navegador), no se debe utilizar para enviar contraseñas ni otros datos sensibles.

<a id="query-string"></a>

## 2. Codificación y Query String

Una *query string* es la parte de la URL que aparece después de `?` y contiene los parámetros de la petición. Cada parámetro se escribe como `nombre=valor`; si hay más de uno, se separan con `&`. Por ejemplo:

```text
/codificacion/procesar2?nombre=Ana+Mar%C3%ADa
```

Los espacios, las tildes y otros caracteres reservados deben representarse con una codificación válida para URL (`+` o `%20` para el espacio, `%C3%AD` para la `í`…). En Java, `URLEncoder.encode(valor, StandardCharsets.UTF_8)` permite codificar un valor antes de incluirlo en una query string. Al recibir la petición, Spring obtiene el valor ya decodificado asociado al parámetro.

<a id="codificar"></a>

### El controlador que codifica

Para verlo en acción, la versión GET del controlador no se limita a recibir el parámetro: lo codifica y pasa **los dos valores** al modelo. El código final del controlador quedó así, con un método privado que prepara el modelo:

```java
@GetMapping("/procesar2")
public String procesadoGet(@RequestParam String nombre, Model modelo) {
    prepararModelo("GET", nombre, modelo);
    return "resultado";
}

private void prepararModelo(String metodo, String valorRecibido, Model modelo) {
    String valorCodificado = URLEncoder.encode(valorRecibido, StandardCharsets.UTF_8);

    modelo.addAttribute("metodo", metodo);
    modelo.addAttribute("textoRecibido", valorRecibido);
    modelo.addAttribute("textoCodificado", valorCodificado);
}
```

Así la vista puede mostrar el texto tal cual llegó y su versión codificada, lado a lado.

<a id="round-trip"></a>

### El viaje de ida y vuelta de un parámetro

La plantilla `resultado.html` cierra el círculo: muestra la cadena codificada y genera un **enlace que reenvía esa misma cadena** como query string:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>LOS DATOS</title>
</head>
<body>
<div>
    <p th:text="${nombre}"></p>
    <p>Resultado de aplicar <code>URLEncoder.encode(valorRecibido, StandardCharsets.UTF_8)</code> en Java:</p>

    <div class="encoded-box">
        <p><strong>Cadena codificada resultante:</strong></p>
        <p><code th:text="${textoCodificado}">texto_codificado</code></p>
    </div>

    <p>Al pulsar el siguiente enlace reenviaremos esta cadena codificada
    directamente en la QueryString al mapping <code>/codificacion/procesar-get</code>:</p>
    <a th:href="'/codificacion/procesar2?nombre=' + ${textoCodificado}" class="btn-link">
        Probar enlace con QueryString codificada
    </a>
</div>
</body>
</html>
```

El enlace se construye concatenando la cadena codificada a mano: `th:href="'/codificacion/procesar2?nombre=' + ${textoCodificado}"`. Al pulsarlo, Spring recibe la petición, **decodifica automáticamente** el valor y la página vuelve a empezar: ahora el texto recibido es el original, y el ciclo puede repetirse. Ese ida y vuelta — codificar al construir la URL, decodificar al recibirla — es la idea central del ejercicio.

La captura muestra el valor codificado y el enlace que lo envía en la query string:

![Valor codificado con URLEncoder y enlace que lo envía en la query string](img%20-%20documents/D4-UD2.7.png)

<div class="note">

Para entender este ejercicio utilicé una herramienta de inteligencia artificial como apoyo: le pedí que explicara el enunciado y el funcionamiento de la codificación paso a paso. Después apliqué esa explicación para comprender el resultado y completar la práctica. En ningún caso copié la solución directamente: la comprobé con Bruno, viendo qué llegaba al servidor y qué salía de él.

</div>

<a id="internacionalizacion"></a>

## 3. Internacionalización (i18n)

La internacionalización permite mostrar los textos de la aplicación en distintos idiomas **sin duplicar plantillas**: el HTML es el mismo y solo cambian los mensajes. En esta práctica el idioma se determina a partir de la petición y los textos se guardan en archivos de propiedades.

<a id="recorrido-i18n"></a>

### Cómo decide la aplicación el idioma

El recorrido básico es siempre el mismo:

1. La petición proporciona una preferencia de idioma, por ejemplo, mediante la cabecera `Accept-Language` o un parámetro como `lang`.
2. Un **`LocaleResolver`** determina la configuración regional (`Locale`) activa; según su implementación, la mantiene entre peticiones o la recalcula cada vez.
3. El **`MessageSource`** busca cada clave de mensaje en el archivo `.properties` correspondiente a ese `Locale`.

Esos dos componentes son los que se configuran en la clase `I18nConfig`. Probé dos formas de resolver el paso 1.

<a id="mensajes"></a>

### Los archivos de mensajes

El archivo por defecto, `messages.properties`, contiene los textos en español:

```properties
app.titulo=Prueba de Internacionalización
app.saludo=¡Hola! Esta aplicación cambia de idioma dinámicamente.
app.instrucciones=Haz clic en los botones para alternar el idioma:
app.idioma.actual=Idioma actual: Español
app.btn.es=Español
app.btn.en=Inglés
```

La variante inglesa, `messages_en.properties`, proporciona las mismas claves en inglés:

```properties
app.titulo=Internationalization Test
app.saludo=Hello! This application changes language dynamically.
app.instrucciones=Click the buttons below to switch languages:
app.idioma.actual=Current language: English
app.btn.es=Spanish
app.btn.en=English
```

Ambos viven en `src/main/resources/`, y la clave es el sufijo del nombre: `_es` y `_en` son los códigos de idioma. Cuando el `Locale` activo es `en`, Spring busca primero en `messages_en.properties`; si una clave no existiera, caería al archivo por defecto `messages.properties`.

<a id="alternativa-a"></a>

### Alternativa A · Cambiar el idioma con `?lang=`

La primera opción que probé fue cambiar el idioma **manualmente** con un parámetro de URL. Utiliza dos piezas: un `SessionLocaleResolver`, que guarda el idioma en la sesión HTTP, y un `LocaleChangeInterceptor`, que vigila las peticiones en busca del parámetro `lang`:

```java
@Bean
public LocaleResolver localeResolver() {
    SessionLocaleResolver resolver = new SessionLocaleResolver();
    resolver.setDefaultLocale(Locale.forLanguageTag("es"));
    return resolver;
}

@Bean
public LocaleChangeInterceptor localeChangeInterceptor() {
    LocaleChangeInterceptor interceptor = new LocaleChangeInterceptor();
    interceptor.setParamName("lang");
    return interceptor;
}

@Override
public void addInterceptors(InterceptorRegistry registry) {
    registry.addInterceptor(localeChangeInterceptor());
}
```

El interceptor actúa **antes** de que el controlador procese la petición: si encuentra el parámetro `lang` (por ejemplo, `?lang=en`), solicita al resolver que actualice el idioma de la sesión. A partir de ahí, todas las peticiones siguientes de ese usuario salen en el idioma elegido, hasta que vuelva a cambiarlo.

<a id="alternativa-b"></a>

### Alternativa B · La cabecera `Accept-Language`

La segunda opción elimina el parámetro y la sesión: el idioma sale directamente de la **cabecera `Accept-Language`** que envía el navegador (o el cliente HTTP) en cada petición. Es la que quedó activa en la versión final del proyecto:

```java
package ruvik.d4ud2.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.LocaleResolver;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.web.servlet.i18n.AcceptHeaderLocaleResolver;

import java.util.Arrays;
import java.util.Locale;

@Configuration
public class I18nConfig implements WebMvcConfigurer {

    @Bean
    public LocaleResolver localeResolver() {
        AcceptHeaderLocaleResolver resolver = new AcceptHeaderLocaleResolver();

        resolver.setDefaultLocale(Locale.of("es"));

        resolver.setSupportedLocales(Arrays.asList(
                Locale.of("es"),
                Locale.of("en")
        ));

        return resolver;
    }
}
```

Tres decisiones que se ven aquí:

- **`setDefaultLocale`**: si la petición no aporta preferencia (o no está entre las admitidas), se responde en español.
- **`setSupportedLocales`**: la aplicación solo habla `es` y `en`. Si un navegador pide `fr`, el resolver no lo acepta y aplica el idioma por defecto.
- Los *imports* de `SessionLocaleResolver` y `LocaleChangeInterceptor` siguen en el archivo aunque ya no se usen: son el recuerdo de la alternativa A. En un proyecto real, sobrarían y habría que quitarlos.

<div class="note">

Detalle curioso que descubrí revisando el código: el archivo `I18nConfig.java` está guardado en la carpeta `ruvik/d4ud2/` pero declara `package ruvik.d4ud2.config;`. Java compila según el paquete **declarado** (la clase acaba en `ruvik/d4ud2/config/` tras compilar), así que funciona igualmente y el escaneo de componentes de Spring la encuentra al ser un subpaquete de la aplicación. Lo limpio sería mover el archivo a su carpeta `config/`, como sí hice con el paquete `controllador`.

</div>

<a id="plantilla-i18n"></a>

### La plantilla: la sintaxis `#{...}`

La pieza que une todo es la vista `mostrarI18n.html`, servida por su propio controlador:

```java
package ruvik.d4ud2.controllador;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class I18Controller {

    @GetMapping("/i18n")
    public String mostrarI18n() {
        return "mostrarI18n";
    }
}
```

Y la plantilla:

```html
<!DOCTYPE html>
<html xmlns:th="http://www.thymeleaf.org" lang="en">
<head>
  <meta charset="UTF-8">
  <title th:text="#{app.titulo}">Título</title>
</head>
<body>
<div class="card">

  <h1 th:text="#{app.titulo}">Título</h1>
  <p th:text="#{app.saludo}">Saludo</p>
  <p th:text="#{app.instrucciones}">Instrucciones</p>
  <p><strong><span th:text="#{app.idioma.actual}">Idioma</span></strong></p>

  <div class="info">
    <p>El idioma de esta página se detecta automáticamente analizando la
    cabecera HTTP <code>Accept-Language</code> enviada por tu navegador o
    cliente HTTP (Bruno / Postman).</p>
  </div>
</div>

<br>
<a th:href="@{/codificacion/formulario}">← Volver al Ejercicio 1</a>
</body>
</html>
```

Aquí está la clave de la internacionalización en Thymeleaf, y conviene no confundirla con lo visto en D2 y D3:

| Sintaxis | Lee de... | Ejemplo |
|---|---|---|
| `${...}` | El **modelo** que preparó el controlador | `${nombre}`, `${saludo.id}` |
| `#{...}` | Los **archivos de mensajes** según el idioma activo | `#{app.titulo}`, `#{app.saludo}` |
| `@{...}` | Genera URLs relativas al contexto | `@{/codificacion/formulario}` |

Un controlador que no añade nada al modelo sigue siendo suficiente: la vista pide los textos directamente al `MessageSource` con `#{clave}`. Por eso `I18Controller` es tan corto.

Las capturas muestran la segunda alternativa en funcionamiento desde Bruno, cambiando el valor de la cabecera. Con `Accept-Language: en`, la página sale en inglés:

![Respuesta de la aplicación en inglés con Accept-Language: en](img%20-%20documents/D4-UD2.8.png)

Y con `Accept-Language: es`, en español:

![Respuesta de la aplicación en español con Accept-Language: es](img%20-%20documents/D4-UD2.9.png)

<div class="note">

Un resto de la evolución: el texto de `app.instrucciones` todavía habla de "botones para alternar el idioma", pero la plantilla final ya no tiene botones — con `AcceptHeaderLocaleResolver` el idioma no se cambia pulsando, sino cambiando la cabecera del cliente. Los archivos de mensajes conservan las claves `app.btn.es` y `app.btn.en` de la versión anterior por si retomo la alternativa A.

</div>

<a id="resumen"></a>

## Resumen de conceptos

### GET y POST

| Aspecto | GET | POST |
|---|---|---|
| Dónde van los datos | En la URL, tras `?` (query string) | En el cuerpo de la petición |
| Visibles en la barra de direcciones | Sí, y quedan en el historial | No |
| Compartibles como enlace | Sí | No |
| Adecuado para | Búsquedas y filtros | Datos sensibles o que modifican algo |
| Codificación | Los valores deben codificarse como URL | Depende del `Content-Type` |

### Errores HTTP encontrados

| Código | Significado | Cuándo me apareció |
|---|---|---|
| **404** | La ruta no existe | En D1, al pedir `/` sin controlador |
| **405** | La ruta existe, pero no para ese método | Aquí: GET a una ruta mapeada solo para POST |
| **400** | Petición mal formada | Caracteres especiales sin codificar en la URL |

### Piezas de la internacionalización

| Elemento | Papel |
|---|---|
| `messages.properties` | Textos por defecto (español) |
| `messages_en.properties` | Textos ingleses; mismo sufijo que el código de idioma |
| `LocaleResolver` | Decide el `Locale` activo a partir de la petición |
| `SessionLocaleResolver` | Guarda el idioma en la sesión HTTP |
| `AcceptHeaderLocaleResolver` | Lee el idioma de la cabecera `Accept-Language` en cada petición |
| `LocaleChangeInterceptor` | Detecta el parámetro `?lang=` y cambia el idioma |
| `setDefaultLocale` / `setSupportedLocales` | Idioma de reserva y lista de idiomas admitidos |
| `#{clave}` en Thymeleaf | Resuelve la clave en el `.properties` del idioma activo |
| `MessageSource` | Componente que busca cada clave en el archivo adecuado |

Ideas clave que me llevo de la práctica:

- La **ruta y el método** deben coincidir con el mapeo: la misma URL puede tener un GET y un POST distintos, y mezclarlos produce un 405.
- En GET los datos viajan **en la URL** y deben estar **codificados**; Spring los decodifica automáticamente al recibirlos, y `URLEncoder.encode` permite codificarlos cuando los construyo yo.
- `#{...}` y `${...}` son cosas distintas: mensajes internacionalizados frente a atributos del modelo.
- La internacionalización separa **el texto de la plantilla** (archivos `.properties`) y **la decisión del idioma** (`LocaleResolver`): se pueden combinar a la carta.
- La alternativa de sesión (`?lang=`) recuerda el idioma del usuario; la de cabecera (`Accept-Language`) lo deduce en cada petición de cómo el cliente se presenta.

<a id="repaso"></a>

## Preguntas de repaso

1. ¿Dónde viajan los datos de un formulario enviado por GET y dónde por POST? ¿Qué consecuencia práctica tiene para contraseñas y enlaces compartibles? *(Envío mediante GET)*
2. ¿Qué significa el error 405 y por qué lo produce enviar un GET a una ruta mapeada con `@PostMapping`? ¿En qué se diferencia del 404? *(El 405 del formulario GET)*
3. ¿Qué es una query string, cómo se separan varios parámetros y cómo se codifican los espacios y las tildes? *(Codificación y Query String)*
4. ¿Qué hace `URLEncoder.encode(valor, StandardCharsets.UTF_8)` y quién decodifica el valor cuando llega al servidor? *(El controlador que codifica)*
5. ¿Qué ventaja aporta `@RequestMapping("/codificacion")` en la clase frente a repetar el prefijo en cada método? *(Envío mediante POST)*
6. ¿Qué tres pasos siguen una petición desde que llega hasta que la vista muestra un texto en el idioma correcto? *(Cómo decide la aplicación el idioma)*
7. ¿Cómo se llaman y dónde se colocan los archivos de mensajes para español e inglés? ¿Qué pasa si el idioma activo no tiene el archivo o falta una clave? *(Los archivos de mensajes)*
8. ¿Qué diferencia hay entre `SessionLocaleResolver` con `LocaleChangeInterceptor` y `AcceptHeaderLocaleResolver`? *(Alternativas A y B)*
9. ¿Para qué sirven `setDefaultLocale` y `setSupportedLocales`? ¿Qué ocurre si el navegador pide un idioma no admitido? *(Alternativa B)*
10. ¿Qué diferencia hay entre `#{app.titulo}`, `${nombre}` y `@{/ruta}` en una plantilla Thymeleaf? *(La plantilla i18n)*
11. ¿Por qué el controlador de `/i18n` no añade nada al modelo y aun así la página muestra textos? *(La plantilla i18n)*
12. ¿Qué controla el `LocaleChangeInterceptor` y en qué momento del ciclo de la petición actúa? *(Alternativa A)*

<a id="conclusion"></a>

## Conclusiones

La práctica me permitió distinguir con Bruno, viéndolo, dónde viajan los datos en una petición GET y en una POST, y comprobar que el método y la ruta del formulario deben coincidir con el mapeo del controlador — el 405 fue un error pequeño pero muy ilustrativo. También aprendí que los valores de una URL deben codificarse correctamente, y construí con `resultado.html` el ciclo completo: codificar al construir el enlace y dejar que Spring decodifique al recibirlo.

La parte de internacionalización requirió más investigación: utilicé la IA como apoyo para entender los conceptos y después los relacioné con la configuración y las pruebas realizadas en Bruno. Quedé con la diferencia nítida entre las dos alternativas (sesión con `?lang=` frente a cabecera `Accept-Language`) y con la sintaxis `#{...}` de Thymeleaf, que hasta ahora no había necesitado.

Con esto se cierra el recorrido de la unidad: D1 montó la aplicación y las primeras rutas; D2 añadió plantillas, objetos y validación; D3 mantuvo el estado entre pasos de un formulario; y esta práctica ha bajado al protocolo para entender cómo viaja todo lo anterior por HTTP y cómo se adapta la aplicación a cada usuario.

<a id="recursos"></a>

## Recursos

- [Repositorio del proyecto en GitHub](https://github.com/KerinR432/DWES2)
- [Documentación de Spring: Internationalization](https://docs.spring.io/spring-framework/reference/web/webmvc/mvc-controller/ann-methods/locale-timezone.html)
- [Javadoc de URLEncoder](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/net/URLEncoder.html)
- Bruno, como cliente HTTP para inspeccionar cabeceras y cuerpos
- Stack Overflow y Gemini, como apoyo para entender la codificación de URL y la configuración i18n

<div class="endmark">
FIN DEL REGISTRO DE NAVEGACIÓN // D4 · UD2
</div>
