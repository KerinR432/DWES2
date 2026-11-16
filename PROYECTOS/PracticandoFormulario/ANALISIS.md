# Análisis del proyecto `PracticandoFormulario`

> Documento de revisión técnica. **No se ha modificado ningún archivo de código.**
> Fecha del análisis: 06/11/2026.

---

## 1. Resumen ejecutivo

El proyecto es un esqueleto de aplicación Spring Boot con Thymeleaf correctamente generado, pero **el formulario no funciona de principio a fin**:

- No tiene botón de envío.
- El formulario apunta a `/formulario`, pero el controlador solo atiende `GET /`.
- No existe ningún receptor de los datos (objeto de formulario, `@ModelAttribute`, `@PostMapping`).
- No hay validación ni página de resultado.

Por tanto, ahora mismo la aplicación solo permite **ver** el formulario. No se puede enviar ni procesar nada.

Además hay varios problemas de accesibilidad, semántica HTML, tipos de campo, validación y pruebas que conviene corregir aunque el envío básico ya funcione.

**Lo que sí está bien:**

- Estructura estándar de Spring Boot (Maven/Gradle, `src/main`, `src/test`).
- Wrapper de Gradle incluido (`gradlew`, `gradlew.bat`, `gradle-wrapper.jar`).
- Dependencias de Spring Boot 4 coherentes: `spring-boot-starter-webmvc`, `spring-boot-starter-thymeleaf` y los starters de test modulares de Boot 4 existen y son correctos.
- `@SpringBootApplication` y el test de contexto están bien situados.
- Thymeleaf está incluido y la plantilla está en `templates`, que es la ubicación correcta.
- `spring-boot-devtools` está como `developmentOnly`, que es lo adecuado.

---

## 2. Inventario del proyecto

```text
PracticandoFormulario/
├── build.gradle
├── settings.gradle
├── gradlew
├── gradlew.bat
├── gradle/wrapper/
│   ├── gradle-wrapper.jar
│   └── gradle-wrapper.properties
├── .gitignore
├── .gitattributes
└── src/
    ├── main/
    │   ├── java/ruvik/practicandoformulario/
    │   │   ├── PracticandoFormularioApplication.java
    │   │   └── ControllerFormulario.java
    │   └── resources/
    │       ├── application.properties
    │       └── templates/
    │           └── formulario.html
    └── test/java/ruvik/practicandoformulario/
        └── PracticandoFormularioApplicationTests.java
```

| Archivo | Función actual | Estado |
|---|---|---|
| `build.gradle` | Configuración de plugins, Java 21 y dependencias | Correcto en lo esencial; falta validación |
| `settings.gradle` | Nombre del proyecto | Correcto |
| `gradle-wrapper.properties` | Fija Gradle 9.7.1 | Correcto y ya cacheado en el equipo |
| `PracticandoFormularioApplication.java` | Punto de entrada | Correcto |
| `ControllerFormulario.java` | Atiende `GET /` y devuelve la vista `formulario` | Incompleto: no hay `POST` |
| `formulario.html` | Formulario HTML estático | Incompleto y con errores de accesibilidad/semántica |
| `application.properties` | Solo define el nombre de la aplicación | Válido pero mínimo |
| `PracticandoFormularioApplicationTests.java` | Test de carga del contexto | Insuficiente: no prueba el formulario |
| `.gitignore` / `.gitattributes` | Ignorados y finales de línea | Correctos |

No existen:

- Clase DTO/objeto de formulario.
- Controlador de `POST`.
- Vista de resultado o confirmación.
- Dependencia de validación (`spring-boot-starter-validation`).
- Recursos estáticos (`static/`), CSS o JavaScript.
- Pruebas de controlador con `MockMvc`.

---

## 3. Stack y configuración

- **Java:** toolchain 21 (LTS). En el equipo hay JDK 21 en `C:\Users\kerin\.jdks` (`ms-21.0.11`, `jbr-21.0.11`), así que Gradle debería encontrarlo. Si no lo encontrara, el build fallaría con “No matching toolchains found”; en ese caso habría que instalar el JDK 21 o añadir el resolver de toolchains de Gradle.
- **Spring Boot:** 4.1.1 (existe y es válida). Como mejora, conviene subir al último parche de la rama 4.1 (4.1.2) por correcciones de errores.
- **Gradle:** 9.7.1, compatible con Spring Boot 4.1.
- **Dependencias actuales:**
  - `spring-boot-starter-thymeleaf`
  - `spring-boot-starter-webmvc` (nombre correcto en Spring Boot 4; no es un error)
  - `spring-boot-devtools` (`developmentOnly`)
  - `spring-boot-starter-thymeleaf-test`
  - `spring-boot-starter-webmvc-test`
  - `junit-platform-launcher`
- **Dependencia que falta:** `spring-boot-starter-validation` para poder usar Bean Validation (`@NotBlank`, `@Min`, `@Valid`, etc.).
- **Puerto:** no se define; se usará el 8080 por defecto. No es un error.
- **Codificación:** Spring Boot usa UTF-8 por defecto, pero la plantilla no declara `charset`, lo que es una mala práctica.

---

## 4. Flujo actual (y dónde se rompe)

1. El navegador pide `GET /`.
2. `ControllerFormulario.mostrarFormulario()` devuelve `"formulario"`.
3. Thymeleaf resuelve `src/main/resources/templates/formulario.html` y devuelve el HTML.
4. El usuario rellena los campos.
5. **No hay botón de envío.** Además, al haber cuatro campos de texto y ningún botón, la “submission implícita” del navegador (pulsar Enter) tampoco envía el formulario en la mayoría de navegadores.
6. Si se forzara el envío, el navegador haría `POST /formulario` con `multipart/form-data`.
7. **No existe ningún `@PostMapping` para `/formulario`** (el controlador solo tiene `GET /`), así que Spring devuelve un **404**.
8. Aunque se añadiera el mapeo, **no hay ningún objeto al que enlazar los campos** ni lógica que los reciba, así que los datos se perderían.
9. No existe página ni mensaje de resultado.

Resumen: el flujo se rompe en el paso 5 y, si se saltara, en el paso 7.

---

## 5. Catálogo de fallos

### Leyenda de severidad

- **Bloqueante:** impide que la funcionalidad principal exista.
- **Alta:** rompe el flujo en cuanto se intente usar o mantener.
- **Media:** afecta a calidad, accesibilidad o robustez.
- **Baja:** mejora recomendable, no impide funcionar.

### Tabla resumen

| ID | Severidad | Fallo | Archivo / línea |
|---|---|---|---|
| F-01 | Bloqueante | No hay botón de envío | `formulario.html` (todo el formulario) |
| F-02 | Bloqueante | `POST /formulario` no está mapeado | `ControllerFormulario.java:8`, `formulario.html:4` |
| F-03 | Bloqueante | No hay objeto de formulario ni recepción de datos | `ControllerFormulario.java` completo |
| F-04 | Bloqueante | No hay ninguna vista ni flujo de resultado | Proyecto completo |
| F-05 | Alta | `enctype="multipart/form-data"` innecesario | `formulario.html:4` |
| F-06 | Alta | No hay validación de servidor ni de cliente | `formulario.html` y controlador |
| F-07 | Alta | La plantilla no usa el enlace de datos de Thymeleaf | `formulario.html` |
| F-08 | Media | `label for` sin `id` correspondiente | `formulario.html:5-15` |
| F-09 | Media | Etiqueta vacía para `cantidadHermanos` | `formulario.html:14` |
| F-10 | Media | `cantidadHermanos` es `type="text"` | `formulario.html:15` |
| F-11 | Media | Falta `<!DOCTYPE html>`, `lang`, `head`, `charset` y `title` | `formulario.html:1-18` |
| F-12 | Media | Textos con errores gramaticales y sin tildes | `formulario.html:11` |
| F-13 | Media | No se conservan los datos si hay error | Sin `th:field` ni `BindingResult` |
| F-14 | Media | No hay patrón PRG (Post/Redirect/Get) | Flujo inexistente |
| F-15 | Media | Sin pruebas del formulario | `PracticandoFormularioApplicationTests.java` |
| F-16 | Baja | Acción absoluta `/formulario` no tiene en cuenta el context path | `formulario.html:4` |
| F-17 | Baja | Falta `autocomplete`, `required`, `maxlength` y ayudas visuales | `formulario.html` |
| F-18 | Baja | Sin estilos ni estados de error/foco | No hay `static/` |
| F-19 | Baja | Nombres de clase e `group` poco convencionales | `ControllerFormulario.java`, `build.gradle:7` |
| F-20 | Baja | `application.properties` demasiado mínimo | `application.properties` |
| F-21 | Informativo | Toolchain 21 con JDK 24 como `java` del sistema | `build.gradle:11-15` |
| F-22 | Informativo | Falta de CSRF solo relevante si se añade seguridad | — |

---

### Detalle de cada fallo

#### F-01. No hay botón de envío (bloqueante)

El formulario no contiene ningún `button` de tipo `submit` ni un `input type="submit"`. Sin botón, el usuario no tiene forma evidente de enviar.

Además, como hay varios campos de texto, la norma HTML de envío implícito con Enter no actúa: el navegador no enviará el formulario al pulsar Enter.

**Cómo se mejora:** añadir un botón de envío dentro del formulario. Opcionalmente, un botón de reinicio. El botón debe tener texto claro (“Enviar”, “Guardar”, etc.).

---

#### F-02. El `POST` va a una ruta que no existe (bloqueante)

- La plantilla envía a `action="/formulario"` con `method="POST"`.
- El controlador solo declara `@GetMapping("/")`.

Resultado: al enviar se produce un **404**. No es un 405 porque no hay ningún mapeo para `/formulario`; si se cambiara la acción a `/` sin añadir el `POST`, entonces sería un **405 Method Not Allowed**.

**Cómo se mejora:** decidir una ruta única y coherente (por ejemplo, `GET /` para mostrar y `POST /` para procesar, o `GET /formulario` + `POST /formulario`). Añadir el método `@PostMapping` correspondiente y hacer que el `action` de la plantilla coincida exactamente. Mejor aún, generar la acción con Thymeleaf para que respete el context path.

---

#### F-03. No hay receptor de datos (bloqueante)

No existe una clase con los campos `nombre`, `apellido`, `capitulo` y `cantidadHermanos`, ni un parámetro `@ModelAttribute` en el controlador. Aunque el `POST` existiera, Spring no tendría dónde enlazar los valores y el formulario no serviría de nada.

**Cómo se mejora:**

- Crear un DTO/objeto de formulario con esos cuatro campos, sus getters/setters y, más adelante, las anotaciones de validación.
- Recibirlo en el controlador con `@ModelAttribute`.
- Añadirlo al modelo en el `GET` para que Thymeleaf pueda enlazarlo.
- Decidir el tipo de `cantidadHermanos`: debe ser numérico (`Integer`), no `String`.
- Decidir si `capitulo` es texto libre, número o una lista cerrada de opciones.

---

#### F-04. No existe flujo de resultado (bloqueante)

No hay vista de resultado, ni confirmación, ni almacenamiento. Tras un envío correcto no hay nada que mostrar.

**Cómo se mejora:** definir qué debe pasar después de enviar:

- Si solo se quiere practicar: mostrar una página de resultado con los datos recibidos.
- Si se quiere persistir: añadir entidad, repositorio, servicio y base de datos.
- Si solo se quiere confirmar: mostrar un mensaje de éxito.

En cualquier caso, conviene usar el patrón **PRG** (Post/Redirect/Get): el `POST` procesa y redirige a un `GET` de resultado, evitando reenvíos al recargar. Si se quieren mostrar los datos tras la redirección, hay que pasarlos como flash attributes, guardarlos en sesión o persistirlos; un `redirect` normal pierde el modelo.

---

#### F-05. `multipart/form-data` innecesario (alta)

El formulario solo envía texto, pero declara `enctype="multipart/form-data"`. Eso obliga a Spring a procesar la petición como multipart sin necesidad, complica el diagnóstico y no aporta nada.

**Cómo se mejora:** eliminar el atributo `enctype` (el valor por defecto, `application/x-www-form-urlencoded`, es el correcto para texto). Solo se usaría `multipart/form-data` si hubiera subida de archivos.

---

#### F-06. Sin validación (alta)

No hay ninguna regla de validación:

- No hay `required` en HTML.
- No hay longitudes máximas.
- No hay comprobación de que `cantidadHermanos` sea un número no negativo.
- No hay validación de servidor.
- No está la dependencia de validación.

Esto no se nota ahora porque no hay `POST`, pero en cuanto se añada, entraría cualquier dato.

**Cómo se mejora:**

- Añadir `spring-boot-starter-validation` al build.
- Anotar el DTO: nombre y apellido no vacíos y con longitud razonable; cantidad de hermanos numérica y mayor o igual que cero; capítulo no vacío.
- Usar `@Valid` y `BindingResult` en el controlador.
- Si hay errores, volver a mostrar el formulario (con los valores conservados) y los mensajes de error.
- Añadir validación HTML (`required`, `min`, `maxlength`, `type="number"`) como primera barrera de usabilidad, **sin sustituir nunca la del servidor**.
- Cuidar el caso de `cantidadHermanos` vacío: si el campo es `Integer`, un texto vacío produce un error de conversión; hay que tratarlo como error de validación y mostrarlo.

---

#### F-07. La plantilla no usa el enlace de datos de Thymeleaf (alta)

`formulario.html` es HTML estático: no tiene `th:object`, `th:field`, `th:action` ni `th:errors`. Por tanto:

- Los valores no se rellenan desde el modelo.
- Los valores no se conservan si la validación falla.
- Los errores no se muestran.
- La acción está escrita a mano y no respeta el context path.

**Cómo se mejora:** usar el objeto de formulario en el modelo y los atributos de Thymeleaf para enlazar cada campo, generar la acción y mostrar errores. Thymeleaf escapará el texto por defecto, lo que también protege frente a XSS al mostrar los datos.

---

#### F-08. Etiquetas no asociadas a los campos (media)

Todos los `label` usan `for="nombre"`, `for="apellido"`, etc., pero los `input` no tienen `id`. Un `label` con `for` debe apuntar al `id` de un control. Sin esa asociación:

- Al hacer clic en la etiqueta no se enfoca el campo.
- Los lectores de pantalla no anuncian correctamente la etiqueta.

**Cómo se mejora:** dar un `id` único a cada `input` y hacer que coincida exactamente con el `for` de su `label`.

---

#### F-09. Etiqueta vacía (media)

`<label for="cantidadHermanos"></label>` no tiene texto. No aporta nada y deja el campo sin nombre accesible.

**Cómo se mejora:** escribir el texto de la etiqueta (“Cantidad de hermanos”) y mantener la asociación con el `id` del campo.

---

#### F-10. Tipo de dato incorrecto para la cantidad de hermanos (media)

`cantidadHermanos` es `type="text"`. Eso permite letras, símbolos y valores negativos desde la interfaz.

**Cómo se mejora:** usar `type="number"`, `min="0"`, `step="1"` y, opcionalmente, `inputmode="numeric"`. En el servidor, validar igualmente con un tipo numérico y una restricción de mínimo.

---

#### F-11. HTML incompleto (media)

Falta:

- `<!DOCTYPE html>` (sin él, el navegador puede entrar en modo quirks).
- `<html lang="es">`.
- `<head>`.
- `<meta charset="UTF-8">`.
- `<meta name="viewport">` para móvil.
- `<title>`.

**Cómo se mejora:** completar el documento HTML con la estructura mínima y declarar el idioma y la codificación. Esto mejora la accesibilidad, el renderizado y la codificación de tildes y signos como `¿`.

---

#### F-12. Textos mejorables (media)

- “¿Que capitulo perteneces?” → “¿A qué capítulo perteneces?”.
- Faltan tildes en “Que”, “capitulo” y “Apellido” (posiblemente “Apellidos”).
- “Apellido” en singular para un campo que probablemente admite dos apellidos.
- El texto de la etiqueta de hermanos está vacío.

**Cómo se mejora:** revisar el copy con alguien del dominio y usar textos claros, en español correcto y con tildes. Si el “capítulo” es una lista cerrada, usar un desplegable; si es un número, usar un campo numérico.

---

#### F-13. Los datos no se conservan al fallar (media)

Sin `th:field`, si el usuario envía datos inválidos y se vuelve a mostrar el formulario, los campos aparecerían vacíos. Es una mala experiencia y obliga a reescribir todo.

**Cómo se mejora:** enlazar los campos al objeto del modelo para que Thymeleaf rellene automáticamente los valores enviados, incluso cuando hay errores.

---

#### F-14. Sin patrón PRG (media)

Si se implementa el `POST` devolviendo directamente la vista de resultado, al recargar el navegador se reenviará el formulario (doble envío). Es un problema clásico.

**Cómo se mejora:** procesar en `POST` y redirigir a un `GET` de resultado. Para mostrar los datos, usar flash attributes, sesión o persistencia.

---

#### F-15. Pruebas insuficientes (media)

El único test comprueba que el contexto de Spring arranca. No verifica:

- Que `GET /` devuelve 200 y la vista correcta.
- Que un `POST` válido redirige o muestra el resultado.
- Que un `POST` inválido vuelve al formulario con errores.
- Que `cantidadHermanos` rechaza texto o negativos.

**Cómo se mejora:** añadir pruebas de controlador con `MockMvc` para los casos anteriores, y pruebas unitarias de validación del DTO si se complica. También conviene comprobar que la plantilla renderiza los mensajes de error.

---

#### F-16. Acción absoluta y context path (baja)

`action="/formulario"` funciona solo si la aplicación se despliega en la raíz. Si se configura un context path, la ruta sería incorrecta.

**Cómo se mejora:** generar la acción con Thymeleaf para que incluya el context path automáticamente.

---

#### F-17. Falta de ayudas de usabilidad (baja)

No hay `autocomplete`, `placeholder`, `maxlength`, `required` ni pistas sobre el formato esperado. Tampoco hay un resumen de errores.

**Cómo se mejora:** añadir `autocomplete` adecuado (`given-name`, `family-name`, etc.), longitudes máximas coherentes con la validación, campos obligatorios marcados y mensajes de ayuda. Mantener la validación de servidor como fuente de verdad.

---

#### F-18. Sin estilos ni estados visuales (baja)

No hay CSS ni recursos estáticos. El formulario funciona, pero no hay jerarquía visual, separación entre campos ni estados de error/foco.

**Cómo se mejora:** añadir una hoja de estilos sencilla (o un framework si el curso lo permite): espaciado, tipografía legible, etiquetas visibles, borde de error y foco claro. No es obligatorio para la funcionalidad, pero mejora mucho la entrega.

---

#### F-19. Convenciones de nombres (baja)

- `ControllerFormulario` sigue el orden “tipo primero”; lo habitual es `FormularioController`.
- `group = 'Ruvik'` usa mayúscula; los group IDs de Maven/Gradle suelen ir en minúsculas (por ejemplo, `ruvik` o `com.ruvik`).

No rompe nada, pero conviene alinearse con las convenciones.

---

#### F-20. Configuración mínima (baja)

`application.properties` solo tiene el nombre de la aplicación. No es un error, pero para este ejercicio puede venir bien:

- Declarar explícitamente el puerto si se necesita.
- Forzar UTF-8 si se detectan problemas de codificación.
- Usar un perfil de desarrollo si se añaden configuraciones distintas de producción.

---

#### F-21. Toolchain 21 frente a JDK 24 del sistema (informativo)

El build pide Java 21, pero el `java` del sistema es JDK 24. En el equipo hay JDK 21 instalado en `C:\Users\kerin\.jdks`, por lo que Gradle debería detectarlo. Si en otro equipo no ocurre, el build fallará al no poder aprovisionar el toolchain. Opciones: instalar el JDK 21, añadir el plugin resolvedor de toolchains o cambiar el toolchain a una versión disponible.

No es un fallo del código, pero es un punto a verificar antes de dar el proyecto por reproducible.

---

#### F-22. CSRF (informativo)

Ahora mismo no hay Spring Security, así que no hay protección CSRF y tampoco es exigible. Si en el futuro se añade seguridad, habrá que incluir el token CSRF en el formulario. No lo consideres un fallo actual.

---

## 6. Problemas de accesibilidad y semántica HTML

Además de F-08, F-09 y F-11:

- No hay un `<main>` ni una estructura de landmarks.
- No hay `<fieldset>`/`<legend>` para agrupar los datos personales, aunque no es imprescindible.
- No se asocian los mensajes de error a los campos (`aria-describedby`, `aria-invalid`).
- El botón de envío no existe, por lo que tampoco hay foco ni texto accesible.
- No hay `<title>` ni `lang`, lo que afecta a lectores de pantalla y traductores.
- El formulario no tiene un texto introductorio que explique qué se va a hacer con los datos.

**Mejora:** completar la estructura semántica, asociar etiquetas y errores, y probar con teclado (Tab, Enter, Espacio) y, si se puede, con un lector de pantalla.

---

## 7. Problemas de UX y contenido

- No hay botón de envío (F-01).
- No hay mensaje de éxito ni de error.
- No se conservan los datos al fallar (F-13).
- El texto “¿Que capitulo perteneces?” es ambiguo e incorrecto (F-12).
- No se explica el formato esperado de cada campo.
- No hay separación visual entre campos.
- No hay página de resultado (F-04).
- No hay confirmación antes de enviar (opcional).

**Mejora:** definir el recorrido completo: rellenar → enviar → validar → corregir o confirmar. Añadir textos claros y un resumen de lo enviado.

---

## 8. Validación y seguridad

### Validación

Ahora no existe. La recomendación es doble:

1. **Cliente:** `required`, `type`, `min`, `maxlength`, `pattern` cuando aporten valor.
2. **Servidor:** Bean Validation en el DTO y `BindingResult` en el controlador. Nunca confiar solo en el navegador.

Casos que deben cubrirse:

- Nombre y apellido no vacíos, sin espacios en blanco y con longitud máxima.
- Capítulo no vacío (y con formato válido según el dominio).
- Cantidad de hermanos numérica, entera, mayor o igual que cero.
- Campo vacío de cantidad de hermanos tratado como error comprensible, no como excepción.
- Recorte de espacios antes de validar (o validación que los rechace).

### Seguridad

- Al mostrar datos introducidos por el usuario, usar `th:text` (escapado automático) y evitar `th:utext`.
- No interpolar datos en HTML sin escapar.
- Si se añade Spring Security, incluir CSRF y revisar permisos.
- No registrar datos personales innecesarios en logs.

---

## 9. Pruebas recomendadas

Como mínimo:

1. `GET /` responde 200 y devuelve la vista del formulario.
2. `POST` con datos válidos redirige al resultado (302) o devuelve la vista de resultado.
3. `POST` con nombre vacío devuelve el formulario (200) y contiene un error de validación.
4. `POST` con apellido vacío, ídem.
5. `POST` con `cantidadHermanos` no numérico devuelve error de conversión/validación.
6. `POST` con `cantidadHermanos` negativo devuelve error.
7. La plantilla renderiza los valores introducidos tras un error.
8. El resultado muestra los datos enviados (si se implementa así).

Además, un test de contexto ya existe y está bien mantenerlo.

---

## 10. Deuda técnica y mejoras opcionales

- Organización por capas o por funcionalidad: para un proyecto tan pequeño no es crítica, pero si crece conviene separar controlador, DTO, servicio y persistencia.
- Añadir un `README.md` con requisitos, cómo arrancar, rutas y ejemplos de uso.
- Añadir un perfil de desarrollo y otro de producción si se despliega.
- Añadir manejo de errores personalizado (página 404, 500) si el proyecto va a crecer.
- Considerar internacionalización (mensajes en `messages.properties`) si se espera más de un idioma.
- Añadir un favicon y recursos estáticos si se quiere una entrega más pulida.
- Unificar el idioma del código: nombres de clases y métodos en inglés, textos visibles en español (o todo en español, pero de forma consistente).

---

## 11. Plan de mejora priorizado

### Fase 1 — Hacer que funcione (imprescindible)

1. Decidir rutas: `GET /` para mostrar y `POST /` para procesar (o `/formulario` para ambas).
2. Crear el DTO con `nombre`, `apellido`, `capitulo` y `cantidadHermanos` (este último numérico).
3. Añadir el `@PostMapping` y recibir el DTO con `@ModelAttribute`.
4. Añadir el botón de envío y corregir el `action`.
5. Crear la vista de resultado o el mensaje de confirmación.
6. Implementar PRG con redirección tras éxito.

### Fase 2 — Validar y conservar datos

1. Añadir `spring-boot-starter-validation`.
2. Anotar el DTO y usar `@Valid` + `BindingResult`.
3. Mostrar errores junto a cada campo y conservar los valores.
4. Añadir validación HTML coherente.

### Fase 3 — Accesibilidad, semántica y UX

1. Completar `DOCTYPE`, `lang`, `head`, `charset`, `viewport` y `title`.
2. Asociar todos los `label` con `id`.
3. Corregir textos y tipos de campo.
4. Añadir estilos, estados de foco y error.
5. Revisar el flujo con teclado.

### Fase 4 — Calidad

1. Añadir tests de `MockMvc` para los casos principales.
2. Renombrar `ControllerFormulario` a `FormularioController` si se desea.
3. Actualizar Spring Boot al último parche 4.1.x.
4. Añadir `README.md` y, si aplica, configuración por perfiles.

### Fase 5 — Opcional

1. Persistencia (JPA + H2/MySQL/PostgreSQL).
2. Seguridad (Spring Security + CSRF).
3. Internacionalización.
4. Página de error personalizada.

---

## 12. Criterios de aceptación

El proyecto se considerará correcto cuando:

- `GET /` devuelve el formulario con estado 200 y codificación UTF-8.
- El formulario tiene botón de envío y una acción que coincide con un `POST` existente.
- Al enviar datos válidos se muestra o redirige a un resultado con los datos.
- Al enviar datos inválidos se vuelve al formulario, se conservan los valores y se muestran errores claros.
- `cantidadHermanos` rechaza texto y valores negativos.
- No se usa `multipart/form-data` sin subida de archivos.
- Todos los `label` están asociados a un `id`.
- El HTML tiene `DOCTYPE`, `lang`, `charset` y `title`.
- Los tests de `GET`, `POST` válido y `POST` inválido pasan.
- El proyecto arranca con `./gradlew bootRun` en un equipo con JDK 21.

---

## 13. Preguntas abiertas

Antes de implementar conviene aclarar:

1. ¿Qué es exactamente “capítulo”? ¿Un número, una lista cerrada de capítulos o texto libre?
2. ¿“Cantidad de hermanos” es obligatoria? ¿Puede ser cero? ¿Tiene un máximo?
3. ¿Qué debe pasar tras enviar: solo mostrar los datos, guardarlos en base de datos o ambas cosas?
4. ¿Se quiere una página de resultado separada o un mensaje en la misma página?
5. ¿“Apellido” debe ser un solo campo o “Apellidos”?
6. ¿Hay requisitos del curso sobre versión de Java, Spring Boot o estilo visual?
7. ¿Se espera usar Bootstrap u otra librería de estilos?

---

## 14. Conclusión

El proyecto está bien creado como base, pero **no es funcional todavía**: falta el envío, el mapeo `POST`, el objeto de datos, la validación y el resultado. Los fallos bloqueantes son pocos y están muy localizados (plantilla y controlador); el resto son mejoras de robustez, accesibilidad y calidad.

Prioridad recomendada: **F-01 a F-04 primero**, luego **F-05 a F-07**, después accesibilidad/UX y, por último, pruebas y pulido.
