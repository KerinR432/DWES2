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
