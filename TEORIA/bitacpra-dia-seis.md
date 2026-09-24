# BACKEND ♨️ JAVA

daremos java y al final PHP

hacer una prueba de concepto con otro lenguaje y framework
con Java si no tenemos ni dieas, en java -> socket -> listen 8080
podemos usarlo y hacer que escuche en servidores concretos 

---

El sengundo enfoque que hay una clase de Java que tiene un servidor web dentro de java la concurrencias fatal, el http de manera basica, es una prueba de concepto de un servidor web minimo 

---

Lo mas serio es unsar elos Servlets en Java, tiene todas las gestiones de HTTP, concurrencia mediante contendores y todo que el programador no debe saber. 

---

es utilizar un framework que se apoya en los Servlets se apoya en y hace mas facil reutilizar programas, nosotros utilizalemos Spring y concretamente Springboot. 

---

tener un servidor apache un cgi con java, pero esto esta mas defasado


TENEMOS 

El **cliente** pide algo 

GET = url
POST = cuerpo
PUT 
PATCH
HEAD 
DELETE 
QUEARY

 
 ## HILOS

un sistema operativo levanta procesos, procesos ligeros 

```text
                                                    APACHE           
                                                            \       /
                                                             \     /
                                                             cegi /
```

prcoeso vs thread

cada proceso tiene su espacio de memoria y solo el accede ahí, thread se levanta en un mismo espacio de memoria. 

Cambio de contesto, en  los thread limitarion los cambios de contexto y lo hiceron mas ligeros, conseguiron lenvar 100 procesos a levantar mil thread. 

__PROBLEMA__ esa memorai podría corromperse, en java hay libreria que se llama thread-safe coordina que no se corrompa.

## MVC

Modelo
Vista 
Controlador

se debe seaprar bien, que la vista solo muestre datos.

### MODELO

el dato que se maneja, existe una capa mas entre modelo y controlador. 

### Controlador

controla los otros dos para funcionen

__CRUD__ 

__POJO__ (Plain Old Java Object) es una clase para contener datos. 

## SPRING

Framework que se llama spring y una variante Springboot que lleva un tomcat integrado. Hoy en día programar en un framework es trabajar en un etorno que hay miles de libreria que sabes como trabajar, es reutilizar codigo, no hacer nada desde cero. 

Springboot se basa en un par de patrones, LoC - DL 

### PATONES DISEÑO

web para aprender diseño: https://refactoring.guru/design-patterns

esto se implementa en **interface**


