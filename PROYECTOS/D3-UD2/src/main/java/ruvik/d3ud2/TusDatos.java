package ruvik.d3ud2;

import lombok.Data;

import java.util.ArrayList;
import java.util.List;

@Data
public class TusDatos {
    private String nombre;
    private List<String> aficciones = new ArrayList<>();
    private String lugar;
    private String sexo;
}
