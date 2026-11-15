package com.example.demo;

import java.util.ArrayList;
import java.util.List;

public class Jugador {
	private String nombre;
	private int intentos;
	private Boolean ganar;
	private Integer oportunidades;
	
	public Jugador() {}
	
	public Jugador(String nombre, int intentos) {
		super();
		this.nombre = nombre;
		this.intentos = intentos;
	}
	public String getNombre() {
		return nombre;
	}
	public void setNombre(String nombre) {
		this.nombre = nombre;
	}
	public int getIntentos() {
		return intentos;
	}
	public void setIntentos(int intentos) {
		this.intentos = intentos;
	}

    public Boolean isGanar() {
        return ganar;
    }

    public void setGanar(Boolean ganar) {
        this.ganar = ganar;
    }

    public Integer getOportunidades() {
        return oportunidades;
    }

    public void setOportunidades(Integer oportunidades) {
        this.oportunidades = oportunidades;
    }

    @Override
	public String toString() {
		return "Jugador [nombre=" + nombre + ", intentos=" + intentos + "]";
	}
	
	
	public static List<Jugador> ejemploFakeListaJugadores() {
		List<Jugador> resultado = new ArrayList<Jugador>();
		resultado.add(new Jugador("Alumno7",2));
		resultado.add(new Jugador("Alumno6",4));
		resultado.add(new Jugador("Alumno1",5));
		resultado.add(new Jugador("Profesor2",6));
		resultado.add(new Jugador("Profesor1",7));
		return resultado;
	}
}
