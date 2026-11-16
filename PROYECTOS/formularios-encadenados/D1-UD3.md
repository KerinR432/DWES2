<div class="cover">
<p class="serial">CUADERNO DE PRÁCTICAS // DESARROLLO WEB EN ENTORNO SERVIDOR</p>

# D1 · UD3<br>SPRING BOOT

<p class="subtitle">Sesiones: mantener el estado entre peticiones (versión suficiente)</p>
<p>Kerin Aguilera</p>
<p class="serial">JAVA 21 · SPRING BOOT 4 · THYMELEAF · NOVIEMBRE 2026</p>
</div>

# Formularios encadenados con sesión (HttpSession)

## Objetivo

En esta práctica se parte del proyecto **formularios-encadenados** (mini-quizz por etapas: nombre, signo, aficiones y resultado) y se elimina el uso de campos ocultos (`hidden`) para transportar el estado entre peticiones. En su lugar, el estado se guarda en el **servidor** mediante `HttpSession`.

El objetivo es comprobar que HTTP sigue siendo sin estado, pero que la memoria del flujo puede vivir en el servidor, evitando que los datos viajen por el navegador y sean manipulables por el usuario.

## Cómo ejecutar el proyecto

El proyecto se encuentra en `PROYECTOS/formularios-encadenados` (puede renombrarse a `D1-UD3`) y utiliza el wrapper de Gradle incluido.

```bash
cd PROYECTOS/formularios-encadenados
./gradlew bootRun
```

En Windows:

```powershell
cd PROYECTOS\formularios-encadenados
.\gradlew.bat bootRun
```

Después se abre el navegador en:

```text
http://localhost:8080/
```

Para ejecutar las pruebas:

```bash
./gradlew test
```

## Recorrido de la práctica

1. Se solicita el nombre.
2. Se selecciona un signo del zodíaco.
3. Se seleccionan aficiones.
4. Se muestra un resumen con los datos introducidos.

El número de etapa (`numEtapa`) ya no se envía en un campo oculto: se guarda en sesión. Lo mismo ocurre con el objeto `Quizz` que acumula las respuestas.

## Controlador y modelo de datos

Un único método `@PostMapping("/")` procesa todos los envíos. El estado se recupera de la sesión y solo se sobrescriben los campos que llegan en la petición actual, de modo que los datos de pasos anteriores no se pierden.

```java
package goya.daw2.pruebas_plantillas;

import java.util.ArrayList;
import java.util.List;

import entity.Quizz;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;

@Controller
public class FormsController {

    static final String[] SIGNOS = { "", "Aries", "Tauro", "Géminis", "Cáncer", "Leo", "Virgo", "Libra", "Escorpio",
            "Sagitario", "Capricornio", "Acuario", "Piscis" };
    static final String[] AFICCIONES = { "Deportes", "Juerga", "Lectura", "Relaciones sociales" };

    private Quizz getQuizz(HttpSession session) {
        Quizz actual = (Quizz) session.getAttribute("quizz");
        if (actual == null) {
            actual = new Quizz();
            session.setAttribute("quizz", actual);
        }
        return actual;
    }

    private int getEtapa(HttpSession session) {
        Integer etapa = (Integer) session.getAttribute("numEtapa");
        if (etapa == null) {
            etapa = 1;
            session.setAttribute("numEtapa", etapa);
        }
        return etapa;
    }

    @PostMapping("/")
    String procesaEtapaX(Model modelo,
                          Quizz quizz,
                          HttpSession session) {

        Quizz actual = getQuizz(session);
        int numEtapa = getEtapa(session);

        if (quizz.getNombre() != null) {
            actual.setNombre(quizz.getNombre());
        }
        if (quizz.getSigno() != null) {
            actual.setSigno(quizz.getSigno());
        }
        if (quizz.getAficciones() != null && !quizz.getAficciones().isEmpty()) {
            actual.setAficciones(quizz.getAficciones());
        }

        modelo.addAttribute("signos", SIGNOS);
        modelo.addAttribute("aficciones", AFICCIONES);
        modelo.addAttribute("quizz", actual);

        String errores = "";

        if (numEtapa == 1 && (actual.getNombre() == null || actual.getNombre().isBlank())) {
            errores = "Debes poner un nombre no vacío";
        } else if (numEtapa == 1 && (actual.getNombre().length() < 3 || actual.getNombre().length() > 10)) {
            errores = "La longitud del nombre debe estar entre 3 y 10";
        }

        if (numEtapa == 2 && (actual.getSigno() == null || actual.getSigno() == 0)) {
            errores = "Debes seleccionar un signo";
        }

        if (numEtapa == 3 && (actual.getAficciones() == null || actual.getAficciones().isEmpty())) {
            errores = "Debes elegir al menos una aficción, no seas soso/a";
        }

        if (!errores.isBlank()) {
            modelo.addAttribute("errores", errores);
            return "etapa" + numEtapa;
        }

        numEtapa++;
        session.setAttribute("numEtapa", numEtapa);

        if (numEtapa == 4) {
            ArrayList<String> respuestas = new ArrayList<String>();
            respuestas.add(actual.getNombre());
            respuestas.add(SIGNOS[actual.getSigno()]);
            respuestas.add(String.join(", ", actual.getAficciones()));
            modelo.addAttribute("respuestas", respuestas);
        }

        return "etapa" + numEtapa;
    }

    @GetMapping("/")
    String getEtapa0(Model modelo, HttpServletRequest request) {
        HttpSession session = request.getSession(true);
        session.invalidate();
        session = request.getSession(true);
        session.setAttribute("quizz", new Quizz());
        session.setAttribute("numEtapa", 1);
        modelo.addAttribute("quizz", new Quizz());
        modelo.addAttribute("signos", SIGNOS);
        modelo.addAttribute("aficciones", AFICCIONES);
        return "etapa1";
    }
}
```

### Modelo de datos

`Quizz` acumula los datos del flujo. Se cambió `aficciones` de `String` a `List<String>` para poder guardar varias selecciones.

```java
package entity;

import java.util.ArrayList;
import java.util.List;

public class Quizz {
    private String nombre;
    private List<String> aficciones = new ArrayList<>();
    private Integer signo;
    private Integer numEtapa;

    public Quizz() { }

    public Quizz(String nombre, List<String> aficciones, Integer signo, Integer numEtapa) {
        this.nombre = nombre;
        this.aficciones = aficciones;
        this.signo = signo;
        this.numEtapa = numEtapa;
    }

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public List<String> getAficciones() { return aficciones; }
    public void setAficciones(List<String> aficciones) { this.aficciones = aficciones; }

    public Integer getSigno() { return signo; }
    public void setSigno(Integer signo) { this.signo = signo; }

    public Integer getNumEtapa() { return numEtapa; }
    public void setNumEtapa(Integer numEtapa) { this.numEtapa = numEtapa; }
}
```

## Plantillas (sin campos ocultos)

Los formularios ya no incluyen `<input type="hidden" name="numEtapa" ...>`. El estado se recupera de sesión.

- `etapa1.html`: pide el nombre.
- `etapa2.html`: selecciona el signo.
- `etapa3.html`: selecciona aficiones (checkboxes `name="aficciones"`).
- `etapa4.html`: muestra el resultado a partir de `respuestas`.

Al recargar `/` se invalida la sesión (`session.invalidate()`), por lo que el flujo empieza de cero.

## Conservación de datos entre peticiones

### Problema anterior
En la versión con campos ocultos, cada `hidden` tenía que repetirse en cada etapa y los datos viajaban por el navegador. Al migrar a sesión, el primer intento sobrescribía el objeto guardado en cada POST, perdiendo los datos de pasos anteriores.

### Solución
Se recuperan `quizz` y `numEtapa` de la sesión. En el POST solo se actualizan los campos que llegan no nulos/no vacíos:

```java
if (quizz.getNombre() != null) {
    actual.setNombre(quizz.getNombre());
}
if (quizz.getSigno() != null) {
    actual.setSigno(quizz.getSigno());
}
if (quizz.getAficciones() != null && !quizz.getAficciones().isEmpty()) {
    actual.setAficciones(quizz.getAficciones());
}
```

Así, los datos de pasos anteriores sobreviven aunque el formulario del paso actual no los envíe.

### Equivalencia: campo hidden → sesión

| Antes (formulario encadenado) | Después (con sesión) |
|---|---|
| `<input type="hidden" name="numEtapa" ...>` | `session.setAttribute("numEtapa", numEtapa)` |
| `<input type="hidden" name="nombre" ...>` | `actual.setNombre(...)` + `session.setAttribute("quizz", actual)` |
| Repetir hidden en cada etapa | Ya está en sesión; no hace falta repetir |
| Datos visibles en código fuente | Datos solo en el servidor |

## Problemas encontrados y soluciones

1. **Pérdida de datos al cambiar de etapa**  
   Causa: se guardaba el objeto recibido en la petición en vez de actualizar el guardado en sesión.  
   Solución: recuperar `actual` de sesión y sobrescribir solo campos no nulos.

2. **Aficiones como lista**  
   Causa: originalmente era `String`; con checkboxes se reciben múltiples valores.  
   Solución: cambiar a `List<String>` y actualizar solo si la lista no está vacía.

3. **Reinicio del flujo**  
   Causa: al volver a `/` la sesión anterior persistía.  
   Solución: `session.invalidate()` en el GET y creación de una sesión nueva con `quizz` y `numEtapa` inicializados.

## Pruebas

El proyecto incluye pruebas básicas de contexto (`FormulariosEncadenadosApplicationTests`). Para el flujo completo con sesión conviene pruebas que reutilicen la misma `MockHttpSession` entre peticiones; en esta versión suficiente se valida manualmente el recorrido por navegador.

## Resumen de conceptos

- `HttpSession` permite guardar objetos en el servidor por usuario.
- `session.setAttribute` / `getAttribute` sustituyen a los campos `hidden`.
- Solo se actualizan los campos que llegan en cada petición.
- `session.invalidate()` reinicia el flujo.
- Los datos pequeños/no sensibles pueden ir en cookie; los de usuario y formularios por pasos, en sesión.

## Recursos

- Apuntes del profesor: `TEORIA/documentanción - profe/D1-UD3.md`
- [Documentación de Spring Boot](https://spring.io/projects/spring-boot)
- [Documentación de Thymeleaf](https://www.thymeleaf.org/documentation.html)

<div class="endmark">
FIN DE LA TRANSMISIÓN // D1 · UD3 (SUFICIENTE)
</div>