				HTTP
				|
			____|______
			|          |
			|		   | 
		SERVIDOR	   |
					ciente


EL SERVIDOR: 
	escuchas e interpreta el HTTP por los puerto 443 y 80 
EL CLIENTE:
	 pide al servidor HTTP usuario y el servidor llo rendiriza al usuario


# COMANDOS UTILIZADOS

`docker ps -a`
ver todos los docker creado, que esta utilizados, los que fallan y los que estan parados

`docker start nombre contenerdor` 
iniciamos algunos dockers que esten parados

`docker stop nombre contenedor`
detenemos los contedores que no quieras utilizar

`docker restart nombre contenedor`
reiniciamos los docker

`nc -4l 8000`
es un comando en linux para hacer un servidor que escuche una sola peteción.

`nc -4t localhost 8000`
Aqui podemos crear un chat en la misma maquina o en otras maquinas.

`nc -4tC www.google.es 80`
es para hacer peteciones a google

`curl http://www.google.es/`
igual otro servicio de peteciones por terminal

`docker exec -ti apache-dwes /bin/bash` entrar diractamente del contendor

`a2enmod cgi` activar el modulo

`exit`
salir del contenedor



# DESCOMPONER UNA CONECIÓN

`GET / HTTP/1.1` -> esta es la petención.

`Host: localhost:8000` -> esta es la cabecera.

`User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:152.0) Gecko/20100101 Firefox/152.0` -> es la agente que contestas


veremos peticiones - cabeceras - lienas en blanco y cuerpo

# DIA

el día de hoy ha sido hacer la primera practica de año, la D1 - UD1 rompiendo el hielo. Lo que hicimos fue realmente ver las cabceras de las peticiones
ver que trae cada cabera y desglozarla. 

Luego hemos visto como en teminal el hace el sh, como funciona los escripts en un servidor apache y hemos encendido un servidor apache para ejecutarlo. 

AL final ha sido un día tranquilo y no mucho mas, asi acaba

__relacionado__ con [[Bitacora-dia-tres]]