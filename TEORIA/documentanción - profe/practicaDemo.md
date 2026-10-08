<div class="cover">
<p class="serial">CUADERNO DE PRÁCTICAS // DESARROLLO WEB</p>

# UD1 · UD2<br>SPRING BOOT

<p><strong>De un proyecto vacío a una API REST</strong></p>
<p>Kerin Aguilera</p>
<p class="serial">JAVA 21 · SPRING BOOT · OCTUBRE 2026</p>
</div>


# TUTORIA UNO

## Inicio

Aqui empezamos a traducir lo que es a traducir y replicar las practicas de las tutorias, al comenzar creamos el proyecto como simepre, esta bes teniendo la dependecia d Thymeleaf. Tras exportar ahora tendremos que hacer lo siguiente, creamos un controller prematuro.

```java
package ruvik.demoformulario;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class ControllerDemoFormulario {
    @GetMapping("/saludos")
    public String saludos(@RequestParam(name = "nombre",required = false,defaultValue = "Mundo") String nombre,
    Model modelo) {
        modelo.addAttribute("nombre", nombre);
        return "saludos";
    }
}
```

La idea de este ejercicio es pode pasarle por URL un nombre y este que saludo al nombre o por default si no se le pasa nada, que salude al mundo. Como indica lo que es el html
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>SALUDOS</title>
</head>
<body>
    <p th:text="|Hola ${nombre}!|"></p>
</body>
</html>
```


![El saludo cordiar](img%20-%20documents/practicaAle1.png)


# TURTORIAL 2


## Inicio 

ahora damos un salto y aprendemos algo nuevo y es que ahora entra en juego lo que es las Entidades o los pojos donde guardamos datos directamente en un objeto 

```java
package ruvik.demoformulario;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;

@Controller
public class ControllerDemoFormulario {
    @GetMapping("/saludos")
    public String formularioSaludos(Model modelo) {
        modelo.addAttribute("saludo", new Saludo());
        return "saludos";
    }

    @PostMapping("/saludos")
    public String saludosEnviado(@ModelAttribute Saludo saludo, Model modelo) {
        modelo.addAttribute("saludo", saludo);
        return "resultado";
    }
}

```

Existen conceptos nuevos, distintos. Tenemos el `new Saludo()` inicializmos el objeto y cuando hagamos el formulario guardamos esos datos.

otro concepto nuevo es el `@ModelAttribute` donde intuyo que decimos que queremos recibir un objeto, ese mismo objeto ser servira en la pagina donde visualizamos los datos. Pero vayamos por parte, miremos el formulario

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>SALUDOS</title>
</head>
<body>
    <h1>Formulario</h1>
    <form action="#" th:action="@{/saludos}" th:object="${saludo}" method="post">
        <p>Id: <input type="text" th:field="*{id}" /> </p>
        <p>Mensaje: <input type="text" th:field="*{contenido}" /> </p>
        <p>Id: <input type="submit" value="submit" />  <input type="reset" value="reset" /> </p>
    </form>
</body>
</html>

```

aqui tambien existen varios conceptos distinto a los que ya conocemos 

`th:action="@{/saludos}"` este sirve para decirle al formulario que cuando se le de al botón de enviar, vaya directamente a ese sitio web
`th:object="${saludo}"` Este concepto segun lo veo, le dice el formulario que los campos que tiene que rellenar son de este "objeto" que se llama saludo

`th:field="*{id}"` este funcona para decirle al formulario que este input, este lugar donde introducimos datos van otra relacionada los datos del siguiente objeto, 

importante a parte de que nombre es distinto este no tiene el simbolo de `$` sino `*` es una diferencia importante y que hay que recordar.


Y ahora el resultado es lo siguiente:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Saludado</title>
</head>
<body>
    <h1>Resultado</h1>
    <p th:text="|id: ${saludo.id}|"></p>
    <p th:text="|contenido: ${saludo.contenido}|"></p>
    <a href="/saludos">Envia otro saludo</a>
</body>
</html>
```

Aqui tenemos nuevas cosas, aunque seguimos mostrando los datos como siempre aqui tenemos `th:text="|id: ${saludo.id}|` que aunque es parecido, aqui le decimos que parte de ese objeto queremos motrar y ver.

introducimos datos en el formulario
![Rellenar datos en formulario](img%20-%20documents/capturaAle2.png)

Luego vemos el resultado:

![Mostrar esos datos del formulario](img%20-%20documents/capturaAle3.png)

y por ultimo podemos volver atras para hacer nuevos datos

![volvemos a pedir datos](img%20-%20documents/capturaAle4.png)

 # TUTORIAL 3

 ## Inicio 
imperial
 Aqui empezamos con otra cosa nueva, antes vimos los objetos aqui veremos las validaciones. aqui hay muchas cosas de las cuales hablar primero creamos lo que sabemos un objeto

 ```java
package ruvik.validacionformulario;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public class FormularioPersona {
    @NotNull
    @Size(min=2, max = 30)
    private String nombre;

    @NotNull
    @Min(18)
    private Integer edad;

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public Integer getEdad() {
        return edad;
    }   

    public void setEdad(Integer edad) {
        this.edad = edad;
    }

    @Override
    public String toString() {
        return "FormularioPersona{" +
                "nombre='" + nombre + '\'' +
                ", edad=" + edad +
                '}';
    }
}

```

luego aqui es donde todo cambia, hay mas cosas nuevas

```java
package ruvik.validacionformulario;

import jakarta.validation.Valid;
import org.springframework.stereotype.Controller;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.servlet.config.annotation.ViewControllerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Controller
public class ControladorWeb implements WebMvcConfigurer {

    public void addVistaControlador(ViewControllerRegistry registro) {
        registro.addViewController("/resultado").setViewName("resultado");
    }

    @GetMapping("/")
    public String verFornulario(FormularioPersona persona) {
        return "formulario";
    }

    @PostMapping("/")
    public String verificarInformacionPersona(@Valid FormularioPersona persona, BindingResult bindingResult) {

        if (bindingResult.hasErrors()) {
            return "formulario";
        }
        return "redirect:/resultado";
    }
}

```
Segun he buscado

```java
    public void addVistaControlador(ViewControllerRegistry registro) {
        registro.addViewController("/resultado").setViewName("resultado");
    }
```
Esto funciona para mapear url directamente en java de html o mas es mapear url directamente en la plantilla o la vista.


Y ahora tenemos 
```java
 public String verificarInformacionPersona(@Valid FormularioPersona persona, BindingResult bindingResult) {
```
Lo que hace **`@valid`** es decir que este formulario tiene validaciones y **`BindingResult`** es quien arroja el resultado de las iteraciones del usuario.

me han saludo muchos error investigando con la IA concretamnete con Gemini me surgerio lo siguiente porque no me funcionaba las validaciones

```java
package ruvik.validacionformulario;

import jakarta.validation.Valid;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.servlet.config.annotation.ViewControllerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Controller
public class ControladorWeb implements WebMvcConfigurer {

    @Override
    public void addViewControllers(ViewControllerRegistry registro) {
        registro.addViewController("/resultado").setViewName("resultado");
    }

    @GetMapping("/")
    public String verFornulario(@ModelAttribute("persona") FormularioPersona persona) {
        return "formulario";
    }

    @PostMapping("/")
    public String verificarInformacionPersona(@Valid @ModelAttribute("persona") FormularioPersona persona, BindingResult bindingResult) {

        if (bindingResult.hasErrors()) {
            return "formulario";
        }
        return "redirect:/resultado";
    }
}
```
Luego fallos pequeños como no cambiar los nombre del ingles al español. El formulario:
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Title</title>
</head>
<body>
  <form action="#" th:action="@{/}" th:object="${persona}" method="post">
    <table>
      <tr>
        <td>Nombre</td>
        <td><input type="text" th:field="*{nombre}" /></td>
        <td th:if="${#fields.hasErrors('nombre')}" th:errors="*{nombre}" >ERROR EN EL NOMBRE</td>
      </tr>

      <tr>
        <td>Edad</td>
        <td><input type="text" th:field="*{edad}" /></td>
        <td th:if="${#fields.hasErrors('edad')}" th:errors="*{edad}">ERROR EN LA EDAD</td>
      </tr>

      <tr>
        <td><button type="submit">Enviar</button></td>
      </tr>
    </table>
  </form>
</body>
</html>
```

Y el resultado:
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Resultado</title>
</head>
<body>
    ¡Felicidades! Tue eres lo bastante mayor para estar en este sitio Web
</body>
</html>
```


Y ahora adjunto muestras que funciona

Fallo con el nombre
![volvemos a pedir datos](img%20-%20documents/capturaAle5.png)

Fallo con la edad
![volvemos a pedir datos](img%20-%20documents/capturaAle6.png)


Correcto
![volvemos a pedir datos](img%20-%20documents/capturaAle7.png)



# PRACTICA DOS

Aqui teniamos que poner en practica lo aprendido de momento no puedo hacer validaciones por el tiempo pero si las demas

Primero cree un objeto o pojo que me gusta mas utilizarlo:
```java
package ruvik.fuerzadelimperio;

import java.util.ArrayList;

public class FormularioImperial {
    private String nombre;

    private Integer edad;

    private ArrayList<String> aficiones;

    private String ramaMilitar;

    private Integer rango;

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public Integer getEdad() {
        return edad;
    }

    public void setEdad(Integer edad) {
        this.edad = edad;
    }

    public String getRamaMilitar() {
        return ramaMilitar;
    }

    public void setRamaMilitar(String ramaMilitar) {
        this.ramaMilitar = ramaMilitar;
    }

    public Integer getRango() {
        return rango;
    }

    public void setRango(Integer rango) {
        this.rango = rango;
    }

    public ArrayList<String> getAficiones() {
        return aficiones;
    }

    public void setAficiones(ArrayList<String> aficiones) {
        this.aficiones = aficiones;
    }
}

```

y por ultimos tenemos los dos html rellenaremos los datos:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Title</title>
</head>
<body>
    <h1>FORMULARIO PARA SERVIR AL EMPERADOR</h1>
    <form action="#" th:action="@{/}" th:object="${imperial}" method="post">
        <p>
            Nombre:
            <input type="text" th:field="*{nombre}" />

        </p>

        <p>Edad: <input type="number" th:field="*{edad}" /> </p>
        <p>Aficiones
        </p>
        <input type="checkbox" th:field="*{aficiones}" value="Deporte" /> Deporte
        <input type="checkbox" th:field="*{aficiones}" value="Arte" /> Arte
        <input type="checkbox" th:field="*{aficiones}" value="Fotografia" /> Fotografia
        <select name="ramaMilitar" th:field="*{ramaMilitar}">
            <option value="" disabled selected >-- Selecciona una opción --</option>
            <option value="Astra Militarun">Astra Militarun</option>
            <option value="Ultramarines">Ultramarines</option>
            <option value="Salamandras" >Salamandras</option>
        </select>

@Controller
public class ControllerDelImperio {

    @GetMapping("/")
    public String mostrarFormulario(FormularioImperial imperial, Model modelo) {
        modelo.addAttribute("imperial", imperial);

        <p>Rango: <input type="range" th:field="*{rango}" min="1"
                         max="10"
                         step="1"
        /> </p>

        <p><button type="submit">Enviar</button></p>

    </form>
</body>
</html>
```



Luego tambien en el controlador donde yo he puesto dos condicones, para vizualizar un tema si eres mayor y de un rango alto:

```java
package ruvik.fuerzadelimperio;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;

@Controller
public class ControllerDelImperio {

    @GetMapping("/")
    public String mostrarFormulario(FormularioImperial imperial, Model modelo) {
        modelo.addAttribute("imperial", imperial);

        return "formulario";
    }

    @PostMapping("/")
    public String procesarFormulario(FormularioImperial imperial, Model modelo) {
        modelo.addAttribute("imperial", imperial);

        if(imperial.getEdad()>18) {
            modelo.addAttribute("esMayor",true);
        }
        if(imperial.getRango()>5) {
            modelo.addAttribute("esAltoRango",true);
        }

        return "tucartilla";
    }
}
```
Y el html que debemos devolver es:
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Title</title>
</head>
<body>
    <h1>BIENVENIDO AL PODEROSO IMPERIO DE LA HUMANIDAD</h1>
    <p>Tu servicio sera en pos del honor, de la gloria. dar tu vida por el emperador</p>

    <h2>Tus datos</h2>

    <p th:text="|Te Llamas: ${imperial.nombre}|"></p>
    <p th:text="|Tu edad es: ${imperial.edad}|"></p>
    <p th:each=" aficion : ${imperial.aficiones}" th:text="|aficiones son: ${aficion}|"></p>
    <p th:text="|Peteneces la gloria: ${imperial.ramaMilitar}|"></p>
    <p th:text="|Tu Rango es: ${imperial.rango}|"></p>

    <div th:if="${esMayor}">
        <p>Eres un tio que entiende que esto va ser un paseo. Aunque servir al emperador es glorioso. Claramente esto va traer destraste y seguramente mueras en menos de unos minutos
        pero genial, tu vida aunque no sea recordarda seguro seras recordado por algo o por alguien, ¡ANIMO!
        </p>
    </div>

    <div th:if="${esAltoRango}">
        <p>
            Comisario, Capitan del capitulo, Astarte.
            Hay muchos planetas bajo ataque, actualemente estamos luchando varios frente. Tu regmiento debe ir aun sitio
        </p>

        <h1>Planetas</h1>
        <h2>Terra</h2>
        <h2>Arcadia</h2>
    </div>
</body>
</html>
```

Primero siendo menores y de bajo rango

![El saludo cordiar](img%20-%20documents/D2-UD1.1.png)

y el resutlado es
![El saludo cordiar](img%20-%20documents/D1-UD2.2.png)



![El saludo cordiar](img%20-%20documents/UD2-UD2.3.png)

# Conclusión

Muchos conceptos nuevos, validaciones simpre se me ha complicado, pero el tema de objeto y modelos me gusta mucho, lo malo son las etiquetas en html que van cambiando segun lo uses.
