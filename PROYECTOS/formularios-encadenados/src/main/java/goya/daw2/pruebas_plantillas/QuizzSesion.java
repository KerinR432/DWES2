package goya.daw2.pruebas_plantillas;

import org.springframework.stereotype.Component;
import org.springframework.web.context.annotation.SessionScope;

import java.util.ArrayList;
import java.util.List;
@Component
@SessionScope
public class QuizzSesion {
    private String nombre;
    private List<String> aficciones = new ArrayList<>();
    private Integer signo;
    private Integer numEtapa;

    public QuizzSesion() {
    }

    public QuizzSesion(String nombre, List<String> aficciones, Integer signo, Integer numEtapa) {
        this.nombre = nombre;
        this.aficciones = aficciones;
        this.signo = signo;
        this.numEtapa = numEtapa;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public List<String> getAficciones() {
        return aficciones;
    }

    public void setAficciones(List<String> aficciones) {
        this.aficciones = aficciones;
    }

    public Integer getSigno() {
        return signo;
    }

    public void setSigno(Integer signo) {
        this.signo = signo;
    }

    public Integer getNumEtapa() {
        return numEtapa;
    }

    public void setNumEtapa(Integer numEtapa) {
        this.numEtapa = numEtapa;
    }

    @Override
    public String toString() {
        final StringBuilder sb = new StringBuilder("QuizzSesion{");
        sb.append("nombre='").append(nombre).append('\'');
        sb.append(", aficciones='").append(aficciones).append('\'');
        sb.append(", signo='").append(signo).append('\'');
        sb.append(", numEtapa=").append(numEtapa);
        sb.append('}');
        return sb.toString();
    }
}
