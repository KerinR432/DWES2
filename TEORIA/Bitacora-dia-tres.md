# COMO ES UNA URL

Una URL puede dividirse en varias partes:

| Parte | Ejemplo | Significado |
|---|---|---|
| **Protocolo** | `https://` | Indica cómo comunicarnos |
| **Host** | `ejemplo.com` | Servidor o destino |
| **Puerto** | `:443` | Puerto de conexión |
| **Ruta** | `/ruta/pagina` | Recurso que queremos solicitar |
| **Parámetros** | `?parametro1=valor1&parametro2=valor2` | Información adicional |
| **Fragmento** | `#seccion` | Sección concreta de la página |

### Ejemplo completo

```text
https://ejemplo.com:443/ruta/pagina?parametro1=valor1&parametro2=valor2#seccion
```


# IDEAS CLARAS PARA CLASES
- ⚠️ HTTP 
    - 80 texto claro
    - sin cifrado

- 🔒 HTTPS 
    - 443
    - ✅ SSL TSL3

```bash
curl https://ejemplo.com
```



## QUE HEMOS APRENDIDO 

Una pagina estatica es la que el cliente es dinamica y dinamica es cuando el servidor ejecuta el codigo.


### PAGINA ESTATICA VS PAGINA DINAMICAS

| Tipo | Peteciones | Tiempo |
| --- | --- | --- |
| **pagina estatica** | 1.000.000/100 | 0.034 ms |
| **pagina dinamica** | 1.000.000/100 | 100 veces mas lento         |

la estatica es rapida, un fichero enviarlo y la dinamica no, debe ejecutar el codigo siempre en el servidor.
una pagina estatica no puede ser porque esta desafadas, pero si puede hacer un escripts que genere esa hora cada X tiempo

### Vistas.sh
```text
En el lado de servidor vs JS el problema que tiene js solo sirve a ese usuario, los cambios solo seran los servidores.
Mientras que el contandor es ejecutado en el lado del servidor, si que lleva ese computo global...
```
El **visitas-sin-lock** cuando se hacen miles de peticiones, se solapan entre ellas y hasta se reinicián.

# SIGUIENTE PRACTICA

Difentes servidores web con plugin pueden ejecutar codigo **cgi-bin** no se usa, por seguridad. Diferentes servidores por medio de framework puede ejecutar codigo mas complejo, el lenguaje que se utiliza en programación web es **PHP** prueba de consectos vamos activar PHP y ver como funciona. 
otro lenguaje que se utiliza **JAVA** sobre todo los **Servlesl** y **JSP** que es introducido directamente en la pagina, **PYTHON** tiene muchos framework como DJANJO **RUBY** tambien tenemos **GO** y tambien microsoft el **.NET**



# DIA