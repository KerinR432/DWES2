# Fuerza del Imperio — versión con Sesiones (sin tocar el proyecto original)

> Ejemplo didáctico: cómo se vería `fuerzaDelImperio` si en lugar de pasar los datos por el formulario (y/o por campos `hidden`) los guardamos en **sesión**.
> El proyecto original **no se modifica**; aquí solo se muestran los trozos clave.

---

## 0. Nota sobre tu proyecto

Tu `fuerzaDelImperio` actual es un **formulario único** (GET `/` muestra el form, POST `/` procesa y muestra la cartilla). No usa campos `hidden`. Si te referías a un proyecto con formularios encadenados (como `formularios-encadenados` o `D3-UD2`), el patrón es el mismo: **cada `<input type="hidden">` se sustituye por un `session.setAttribute(...)`**.

---

## 1. Controlador con sesión (versión mínima del mismo flujo)

```java
package ruvik.fuerzadelimperio;

import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;

@Controller
public class ControllerDelImperio {

    // GET "/" : si ya hay datos en sesión, los reutiliza (no se pierden al volver)
    @GetMapping("/")
    public String mostrarFormulario(HttpSession session, Model modelo) {
        FormularioImperial imperial = (FormularioImperial) session.getAttribute("imperial");
        if (imperial == null) {
            imperial = new FormularioImperial();
        }
        modelo.addAttribute("imperial", imperial);
        return "formulario";
    }

    // POST "/" : procesa, guarda en sesión y muestra la cartilla
    @PostMapping("/")
    public String procesarFormulario(FormularioImperial imperial, Model modelo, HttpSession session) {
        session.setAttribute("imperial", imperial);   // <-- aquí se guarda en sesión

        modelo.addAttribute("imperial", imperial);

        if (imperial.getEdad() != null && imperial.getEdad() > 18) {
            modelo.addAttribute("esMayor", true);
        }
        if (imperial.getRango() != null && imperial.getRango() > 5) {
            modelo.addAttribute("esAltoRango", true);
        }

        return "tucartilla";
    }

    // Borrar la sesión (ej. "Volver a empezar" sin arrastrar datos)
    @PostMapping("/reset")
    public String reset(HttpSession session) {
        session.invalidate();   // o session.removeAttribute("imperial");
        return "redirect:/";
    }
}
```

### Qué cambió respecto al original
- `mostrarFormulario` ahora recibe `HttpSession` y **recupera** el `FormularioImperial` guardado; si no existe, crea uno vacío.
- `procesarFormulario` hace `session.setAttribute("imperial", imperial)` para que los datos sobrevivan entre peticiones.
- Añadido `/reset` para invalidar la sesión (logout / empezar de cero).

> El cast `(FormularioImperial) session.getAttribute(...)` genera warning → usa `@SuppressWarnings("unchecked")` justo encima de la variable (ver apunte de `@SuppressWarnings`).

---

## 2. Plantillas: adiós a los campos `hidden`

Como los datos viven en sesión, **no necesitas** `<input type="hidden">` para arrastrar `nombre`, `edad`, etc. entre pasos.

### `formulario.html`
Sin cambios relevantes: `th:field` ya enlaza con el objeto `imperial` del modelo. Si vienes de sesión, los campos aparecen rellenos.

### `tucartilla.html`
Sin cambios: sigue leyendo `${imperial.nombre}`, `${imperial.edad}`, etc. del modelo, que el controlador pone desde la sesión.

### Botón "Volver a empezar" (opcional)
```html
<form th:action="@{/reset}" method="post">
    <button type="submit">Volver a empezar</button>
</form>
```

---

## 3. Equivalencia: campo `hidden` → sesión (patrón general)

Si tuvieras un flujo encadenado (varios pasos), cada hidden se convierte así:

| Antes (formulario encadenado) | Después (con sesión) |
|---|---|
| `<input type="hidden" name="nombre" th:value="${nombre}" />` | `session.setAttribute("nombre", nombre)` en el POST del paso 1 |
| Leer en el siguiente paso con `@RequestParam("nombre")` | Leer con `(String) session.getAttribute("nombre")` |
| Repetir el hidden en cada etapa | Ya está en sesión; no hace falta repetir |
| Datos visibles en la URL / código fuente | Datos solo en el servidor |

### Ejemplo de paso intermedio con sesión
```java
@PostMapping("/paso2")
public String paso2(@RequestParam("signo") String signo,
                    HttpServletRequest request,
                    Model modelo) {
    // Recuperar lo guardado en el paso 1
    HttpSession session = request.getSession();
    String nombre = (String) session.getAttribute("nombre");

    // Guardar el nuevo dato
    session.setAttribute("signo", signo);

    modelo.addAttribute("nombre", nombre);
    modelo.addAttribute("signo", signo);
    return "etapa3";
}
```

---

## 4. Cookies propias vs sesión (recordatorio)

- La sesión usa automáticamente la cookie `JSESSIONID` (gestionada por Tomcat/Spring). Tú no la creas.
- Si quieres guardar una preferencia pequeña y persistente (idioma, tema), usa una **cookie propia** (ver `Cookies-y-Sesiones.md` → sección Cookies en Spring Boot).
- Para los datos del formulario (nombre, edad, aficiones, rango) → **sesión**.

---

## 5. Resumen

1. Recibe `HttpSession session` en el controlador.
2. Guarda con `session.setAttribute("clave", objeto)`.
3. Lee con `(Tipo) session.getAttribute("clave")`.
4. Elimina hidden fields de las plantillas: la sesión ya arrastra el estado.
5. Para empezar de cero: `session.invalidate()`.
6. No modifiques el proyecto original; copia estos patrones cuando te lo pidan.