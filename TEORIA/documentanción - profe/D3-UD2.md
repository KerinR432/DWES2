<div class="cover">
<p class="serial">CUADERNO DE PRÁCTICAS // DESARROLLO WEB</p>

# D3 · UD2<br>SPRING BOOT

<p class="subtitle"><strong>Formularios encadenados</strong></p>
<p>Kerin Aguilera</p>
<p class="serial">JAVA 21 · SPRING BOOT · OCTUBRE 2026</p>
</div>

<div class="toc">
<p class="toc-title">ÍNDICE DE RUTA</p>
<ol>
<li><a href="#objetivo">Objetivo de la práctica</a></li>
<li><a href="#recorrido">Recorrido del formulario</a></li>
<li><a href="#primera-version">Primera versión: formularios encadenados</a></li>
<li><a href="#primera-logica">Primera lógica del controlador</a></li>
<li><a href="#segunda-version">Segunda versión: navegación por pasos</a></li>
<li><a href="#resultado">Resultado, navegación y conservación de datos</a></li>
<li><a href="#resumen">Resumen de conceptos</a></li>
</ol>
</div>

# Formularios encadenados con Spring Boot

<a id="objetivo"></a>

## Objetivo

En esta práctica se construye un formulario dividido en varios pasos. En cada paso se solicitan datos distintos y, al final, se muestra un resumen con toda la información introducida.

El ejemplo utiliza Spring Boot, Thymeleaf y un objeto Java (`TusDatos`) para enlazar los campos del formulario con el modelo. Como las peticiones HTTP no conservan automáticamente el estado entre una página y otra, los datos ya introducidos deben volver a enviarse en los formularios siguientes.

<a id="recorrido"></a>

### Recorrido de la práctica

1. Se solicita el nombre.
2. Se seleccionan las aficiones.
3. Se elige un lugar.
4. Se indica el sexo.
5. Se muestra un resumen con los datos y las opciones para volver atrás o empezar de nuevo.

<a id="primera-version"></a>

## Primera versión: avanzar entre formularios

### Paso 1 · Introducir el nombre

El primer formulario no necesita campos ocultos: todavía no hay datos anteriores que conservar. El atributo `th:object` vincula los campos al objeto que recibe la plantilla.

```html
<!DOCTYPE html>
<html lang="es" xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <title>Formulario 1</title>
</head>
<body>
    <form method="post" th:action="@{/procesar}" th:object="${tusDatos}">
        <label for="nombre">Nombre:</label>
        <input id="nombre" type="text" th:field="*{nombre}">

        <button type="submit" name="contador" value="1">Enviar</button>
    </form>
</body>
</html>
```

Para comprobar los datos recibidos, se pueden imprimir temporalmente en la consola desde el controlador:

```java
System.out.println(datos);
System.out.println(siguiente);
```

Por ejemplo, después de enviar el nombre, la consola puede mostrar:

```text
TusDatos(nombre=Ruvik, Aficciones=[], lugar=null, datosFinales=[])
1
```

Así se ve el primer formulario:

![Primer paso: introducción del nombre](img%20-%20documents/D3-UD2.1.png)

### Paso 2 · Seleccionar las aficiones

El segundo formulario recibe el nombre del paso anterior. El campo oculto `nombre` permite volver a enviarlo junto con las nuevas selecciones.

```html
<!DOCTYPE html>
<html lang="es" xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <title>Formulario 2</title>
</head>
<body>
    <form method="post" th:action="@{/procesar}" th:object="${datos}">
        <fieldset>
            <legend>Selecciona tus aficiones:</legend>

            <label><input type="checkbox" th:field="*{Aficciones}" value="Fútbol"> Fútbol</label>
            <label><input type="checkbox" th:field="*{Aficciones}" value="Baloncesto"> Baloncesto</label>
            <label><input type="checkbox" th:field="*{Aficciones}" value="Voleibol"> Voleibol</label>
            <label><input type="checkbox" th:field="*{Aficciones}" value="Bádminton"> Bádminton</label>
        </fieldset>

        <button type="submit" name="contador" value="1">Enviar</button>
        <input type="hidden" th:field="*{nombre}">
    </form>
</body>
</html>
```

Vista del formulario:

![Segundo paso: selección de aficiones](img%20-%20documents/D3-UD2.2.png)

En la primera implementación, la consola muestra cómo se incorporan los datos paso a paso:

```text
TusDatos(nombre=Ruvik, Aficciones=[], lugar=null, datosFinales=[])
1
TusDatos(nombre=Ruvik, Aficciones=[Baloncesto, Bádminton], lugar=null, datosFinales=[])
2
```

### Paso 3 · Elegir un lugar

El tercer formulario añade el lugar y vuelve a enviar los datos de los pasos anteriores. Para conservar una colección, como `Aficciones`, se genera un campo oculto por cada elemento.

```html
<!DOCTYPE html>
<html lang="es" xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <title>Formulario 3</title>
</head>
<body>
    <form method="post" th:action="@{/procesar}" th:object="${datos}">
        <label for="lugar">Lugar:</label>
        <select id="lugar" th:field="*{lugar}">
            <option value="">-- Selecciona una opción --</option>
            <option value="Madrid">Madrid</option>
            <option value="Sevilla">Sevilla</option>
            <option value="Málaga">Málaga</option>
        </select>

        <button type="submit" name="contador" value="1">Enviar</button>

        <input type="hidden" th:field="*{nombre}">
        <th:block th:each="aficcion : ${datos.Aficciones}">
            <input type="hidden" name="Aficciones" th:value="${aficcion}">
        </th:block>
    </form>
</body>
</html>
```

Vista del formulario:

![Tercer paso: selección del lugar](img%20-%20documents/D3-UD2.3.png)

Después de seleccionar, por ejemplo, Sevilla, el objeto contiene los datos de los tres pasos:

```text
TusDatos(nombre=Ruvik, Aficciones=[], lugar=null, datosFinales=[])
1
TusDatos(nombre=Ruvik, Aficciones=[Baloncesto, Bádminton], lugar=null, datosFinales=[])
2
TusDatos(nombre=Ruvik, Aficciones=[Baloncesto, Bádminton], lugar=Sevilla, datosFinales=[])
3
```

<a id="primera-logica"></a>

## Primera lógica del controlador

En la primera versión, un método `@PostMapping` procesa todos los envíos. El parámetro `contador` indica qué paso se ha completado y determina qué plantilla se muestra a continuación.

```java
@PostMapping("/procesar")
public String procesarDatos(
        @ModelAttribute TusDatos datos,
        @RequestParam("contador") String contador,
        Model modelo) {

    siguiente += Integer.parseInt(contador);
    System.out.println(datos);
    System.out.println(siguiente);

    if (siguiente == 1) {
        modelo.addAttribute("datos", datos);
        return "Formulario2";
    }

    if (siguiente == 2) {
        modelo.addAttribute("datos", datos);
        return "Formulario3";
    }

    modelo.addAttribute("datos", datos);
    return "Resultado";
}
```

Esta primera aproximación utiliza un contador global:

```java
static int siguiente = 0;
```

Es una solución sencilla para probar el recorrido, pero no es adecuada para varios usuarios: el valor se comparte entre todas las peticiones y puede quedar desincronizado. La siguiente versión obtiene el paso actual de cada petición, en lugar de guardarlo en una variable estática.

### Modelo de datos

`TusDatos` reúne la información que se va completando en los distintos formularios. Lombok genera los métodos habituales, como los *getters* y *setters*, mediante `@Data`.

```java
package ruvik.d3ud2;

import lombok.Data;
import java.util.ArrayList;

@Data
public class TusDatos {
    private String nombre;
    private ArrayList<String> Aficciones = new ArrayList<>();
    private String lugar;
    private ArrayList<String> datosFinales = new ArrayList<>();
    private String sexo;
}
```

<a id="segunda-version"></a>

## Segunda versión: navegación con el valor de `contador`

La nueva versión utiliza el valor recibido en la petición para decidir qué vista mostrar. Así se evita acumular el estado en una variable global.

```java
package ruvik.d3ud2.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import ruvik.d3ud2.TusDatos;

@Controller
public class ControladorFormulariosEncadenado {

    @GetMapping("/formulario1")
    public String formulario1(@ModelAttribute TusDatos tusDatos, Model model) {
        model.addAttribute("tusDatos", tusDatos);
        return "Formulario1";
    }

    @PostMapping("/procesar")
    public String procesarDatos(
            @ModelAttribute TusDatos datos,
            @RequestParam("contador") Integer contador,
            Model modelo) {

        System.out.println(datos);
        System.out.println(contador);

        if (contador == 0) {
            return "redirect:/formulario1";
        }

        modelo.addAttribute("datos", datos);
        modelo.addAttribute("contador", contador);

        if (contador == 1) {
            return "Formulario2";
        }
        if (contador == 2) {
            return "Formulario3";
        }
        if (contador == 3) {
            return "Formulario4";
        }

        return "Resultado";
    }
}
```

Los botones envían el número del paso siguiente. En los botones para retroceder, envían el número del paso anterior. El botón para empezar de nuevo envía `0`.

### Paso 4 · Añadir el sexo

El cuarto formulario incorpora una selección con botones de opción. También debe reenviar los valores anteriores para que sigan disponibles al procesar el formulario.

```html
<!DOCTYPE html>
<html lang="es" xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <title>Formulario 4</title>
</head>
<body>
    <form method="post" th:action="@{/procesar}" th:object="${datos}">
        <fieldset>
            <legend>Sexo:</legend>
            <label><input type="radio" th:field="*{sexo}" value="M"> M</label>
            <label><input type="radio" th:field="*{sexo}" value="F"> F</label>
        </fieldset>

        <button type="submit" name="contador" th:value="${contador + 1}">Enviar</button>
        <button type="submit" name="contador" th:value="${contador - 1}">Volver atrás</button>

        <input type="hidden" th:field="*{nombre}">
        <th:block th:each="aficcion : ${datos.Aficciones}">
            <input type="hidden" name="Aficciones" th:value="${aficcion}">
        </th:block>
        <input type="hidden" th:field="*{lugar}">
    </form>
</body>
</html>
```

El formulario se muestra así:

![Cuarto paso: selección del sexo](img%20-%20documents/D3-UD2.4.png)

<a id="resultado"></a>

## Resultado y navegación

La vista final presenta los datos recibidos. `th:text` inserta valores en el contenido HTML y `th:each` recorre la lista de aficiones.

```html
<!DOCTYPE html>
<html lang="es" xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <title>Resumen de datos</title>
</head>
<body>
    <h1 th:text="|Te llamas: ${datos.nombre}|"></h1>

    <p>Tus aficiones:</p>
    <ul>
        <li th:each="aficcion : ${datos.Aficciones}" th:text="${aficcion}"></li>
    </ul>

    <p th:text="|Tu lugar: ${datos.lugar}|"></p>
    <p th:text="|Sexo: ${datos.sexo}|"></p>

    <form method="post" th:action="@{/procesar}" th:object="${datos}">
        <button type="submit" name="contador" th:value="${contador - 1}">Volver atrás</button>
        <button type="submit" name="contador" value="0">Volver al inicio</button>

        <input type="hidden" th:field="*{nombre}">
        <th:block th:each="aficcion : ${datos.Aficciones}">
            <input type="hidden" name="Aficciones" th:value="${aficcion}">
        </th:block>
        <input type="hidden" th:field="*{lugar}">
        <input type="hidden" th:field="*{sexo}">
    </form>
</body>
</html>
```

La captura muestra el resultado final:

![Resumen final de los datos](img%20-%20documents/D3-UD2.5.png)

### Problema · Se pierden los datos al volver atrás

Al probar la navegación hacia atrás, los datos de los pasos anteriores desaparecían. La causa era que el formulario enviaba solo el campo visible del paso actual. Los valores previos no llegaban al controlador y, por tanto, no podían volver a incluirse en el modelo.

### Solución · Reenviar los valores anteriores

Se añadieron campos ocultos a los formularios para volver a enviar los datos ya introducidos. Para campos simples se puede utilizar `th:field`; para la lista de aficiones se genera un campo oculto por cada elemento.

Los campos ocultos sirven para transportar valores entre peticiones, pero el usuario puede modificarlos desde el navegador. No deben utilizarse para guardar información sensible ni para confiar en valores que el servidor no haya validado.

![Consulta realizada para resolver la pérdida de datos](img%20-%20documents/D3-UD2.6.png)

<a id="resumen"></a>

## Resumen de conceptos

- `@ModelAttribute` enlaza los campos enviados con el objeto `TusDatos`.
- `th:object` indica el objeto del formulario y `th:field` vincula sus propiedades a los controles.
- Los campos ocultos reenvían datos previos que no aparecen como controles editables en el paso actual.
- El parámetro `contador` permite avanzar, retroceder o volver al inicio.
- Un contador `static` comparte estado entre usuarios; es preferible obtener el paso de cada petición o gestionar el estado con una solución apropiada para la aplicación.

## Recursos

- [Repositorio del proyecto en GitHub](https://github.com/KerinR432/DWES2)
- Stack Overflow
- Gemini

<div class="endmark">
FIN DE LA TRANSMISIÓN // D3 · UD2
</div>
