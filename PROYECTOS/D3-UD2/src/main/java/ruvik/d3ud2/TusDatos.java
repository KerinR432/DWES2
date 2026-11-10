package ruvik.d3ud2;

import lombok.Data;

import java.util.ArrayList;
@Data
public class TusDatos {
    private String nombre;
    private ArrayList<String> Aficciones = new ArrayList<>();
    private String lugar;
    private String sexo;


    public TusDatos() {
    }
}
