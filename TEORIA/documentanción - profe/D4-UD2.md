<div class="cover">
<p class="serial">CUADERNO DE PRÁCTICAS // DESARROLLO WEB</p>

# D4 · UD2<br>SPRING BOOT

<p class="subtitle"><strong>Codificación UD2</strong></p>
<p>Kerin Aguilera</p>
<p class="serial">JAVA 21 · SPRING BOOT · OCTUBRE 2026</p>
</div>



# EJERCICIOS NUMERO 1º

## PROCESADO POR POST
Estamos revisando podemos enviar cualquier tipo de dato por URL en este caso lo hemos echo primero por medio de POST y utilizando bruno para visualizar y ver que manda

Nosotros intemos enviar el siguiente mensaje
![muestra de codifacion](img%20-%20documents/D4-UD2.2.png)

Y tenemos que buscar directamnete el content-Type lo siguiente:
![Los datos del Content-Type](img%20-%20documents/D4-UD2.1.png)

Mientras tanto nuestro codigo en Java es el siguiente:

```JAVA
package ruvik.d4ud2.controllador;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
@RequestMapping("/codificacion")
public class controllador {

    @GetMapping
    public String mostrarFormulario(){
        return "formulario";
    }

    @PostMapping("/procesar")
    public String procesar(@RequestParam String nombre, Model modelo) {
        modelo.addAttribute("nombre", nombre);
        return "resultado";
    }

}
```
### 🚨 DECTETADO: error en la zona

El siguiente error es que cuando se quiere enviar una petección get peta. Pero encontrar el fallo concreto. 

Mi codigo Java es el siguente:

```java

package ruvik.d4ud2.controllador;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
@RequestMapping("/codificacion")
public class controllador {

    @GetMapping
    public String mostrarFormulario(){
        return "formulario";
    }

    @PostMapping("/procesar")
    public String procesar(@RequestParam String nombre, Model modelo) {
        modelo.addAttribute("nombre", nombre);
        return "resultado";
    }

    @GetMapping("/procesar2")
    public String procesadoGet(@RequestParam String nombre, Model modelo) {
        modelo.addAttribute("nombre", nombre);
        return "resultado";
    }

}

```

el fallo esta en el formulario y es que lo redirigo el precesado incorrecto:

```html
    <form method="GET" action="/codificacion/procesar" enctype="multipart/form-data">
    
```
**asi se vevía el fallo pero ya esta solucionado:** ![errores de enviar un dato en post a get](img%20-%20documents/D4-UD2.3.png)

## PROCESADO POR GET

El get es practiamente lo mismo, solo que cambia una cosa es el envio por URL y la URL se visualiza tambien el resultado que no tiene nada que ver con lo enviado y visualizado:
![La url con caracteres que no se entiende](img%20-%20documents/D4-UD2.4.png)
### 🚨 DECTETADO: error en la zona
Eh intenteado escribirlo solo por la URL y me sal el siguiente fallo:

![error al intentar cambiar datos directo de la URL](img%20-%20documents/D4-UD2.6.png)


## QUERY-STRING

para ser sinceros utilice la IA en este caso para que me explique. Primero no sabia que pedía y segundo pues tampooco sabia como usarlo, pedi que me mostrara como era lo que se pedía y que me explicara paso a paso las funciones que tiene y como usarlo.

Asi que todo lo plasmado aqui fue ese trabajo en conjunto. 

Aqui esta el resultado, lo que he implentado fue la IA explicando paso a paso el "porque"

![datos mostrados del encode](img%20-%20documents/D4-UD2.7.png)

# EJERCICIOS NUMERO 2º

Documentado me para hacer este ejercicio salio los 3 pilares de i18n

salia 

```text

HTTP recopila el **lang**

LocaleChangeInterceptor escucha este parametro lang

LocalResolver guarda el idioma activado

MessageSource busca la clave en message.propities

```

tenemos los archivos creados

el mensaje por defecto
```properties
app.titulo=Prueba de Internacionalización
app.saludo=¡Hola! Esta aplicación cambia de idioma dinámicamente.
app.instrucciones=Haz clic en los botones para alternar el idioma:
app.idioma.actual=Idioma actual: Español
app.btn.es=Español
app.btn.en=Inglés
```

el mensaje en ingles:
```properties
app.titulo=Internationalization Test
app.saludo=Hello! This application changes language dynamically.
app.instrucciones=Click the buttons below to switch languages:
app.idioma.actual=Current language: English
app.btn.es=Spanish
app.btn.en=English
```


va ir buscando en esto archivos el valor e ira buscando en todo lo que messages.propities que existe.

Ahora viene una movida grande, el hecho de configurar i18n

```java

    @Bean
    public LocaleResolver localeResolver() {
        SessionLocaleResolver slr = new SessionLocaleResolver();
        slr.setDefaultLocale(Locale.of("es"));
        return slr;
    }
```

literal esta varibale se encagar de **¿Que idioma deberia preguntarle al usuario?**

```JAVA
    @Bean
    public LocaleChangeInterceptor localeChangeInterceptor() {
        LocaleChangeInterceptor lci = new LocaleChangeInterceptor();
        lci.setParamName("lang");
        return lci;
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(localeChangeInterceptor());
    }
```

Este es el que esta en la puerta esperando a que entre peticiones, esta esperando algo enconcreto antes de que el controller actue o responda algo.

por ejemplo puede estar esperando **?lang=en**  
al ver que es en este manda un mensaje a LocaleResolver para que actualice el idioma


es curioso que aqui existe tambien varios titpos de Resolver para sessiones que es el SessionLocaleResolver.
Para cookies que es el CookieLocaleResolver.
El normal o por defecto el AcceptHeaderLocaleResolver.


esta es le versión con el acceptHeaderLocaleResolver

```java
package ruvik.d4ud2.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.LocaleResolver;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.web.servlet.i18n.AcceptHeaderLocaleResolver;
import org.springframework.web.servlet.i18n.LocaleChangeInterceptor;
import org.springframework.web.servlet.i18n.SessionLocaleResolver;

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

Y asi funcionaria con bruno

![en ingles](img%20-%20documents/D4-UD2.8.png)


y asi seria en español

![en español](img%20-%20documents/D4-UD2.9.png)


me he detido a explicar mas esto, porque entre no lo entendia ni sabia como hacerlo, el pedi ayuda a la IA y que me explicar deteninamente porque de cada cosa


## Recursos
- [Repositorio del proyecto en GitHub](https://github.com/KerinR432/DWES2)
- Stack Overflow
- Gemini
- mi documentación anterior

<div class="endmark">
FIN DE LA TRANSMISIÓN // D4 · UD2
</div>
