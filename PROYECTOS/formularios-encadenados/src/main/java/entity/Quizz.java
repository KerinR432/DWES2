package entity;

public class Quizz {
    private String nombre;
    private String aficciones;
    private Integer signo;
    private Integer numEtapa;

    public Quizz() {
    }

    public Quizz(String nombre, String aficciones, Integer signo, Integer numEtapa) {
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

    public String getAficciones() {
        return aficciones;
    }

    public void setAficciones(String aficciones) {
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
        final StringBuilder sb = new StringBuilder("Quizz{");
        sb.append("nombre='").append(nombre).append('\'');
        sb.append(", aficciones='").append(aficciones).append('\'');
        sb.append(", signo='").append(signo).append('\'');
        sb.append(", numEtapa=").append(numEtapa);
        sb.append('}');
        return sb.toString();
    }
}
