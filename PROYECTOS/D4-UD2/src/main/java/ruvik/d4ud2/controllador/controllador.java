package ruvik.d4ud2.controllador;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

@Controller
@RequestMapping("/codificacion")
public class controllador {

    @GetMapping
    public String mostrarFormulario(){
        return "formulario";
    }

    @PostMapping("/procesar")
    public String procesar(@RequestParam String nombre, Model modelo) {
        modelo.addAttribute("nombre", nombre);
        return "resultado";
    }

    @GetMapping("/procesar2")
    public String procesadoGet(@RequestParam String nombre, Model modelo) {
        prepararModelo("GET",nombre,modelo);
        return "resultado";
    }


    private void prepararModelo(String metodo,String valorRecibido, Model modelo) {
        String valorCodificado = URLEncoder.encode(valorRecibido, StandardCharsets.UTF_8);

        modelo.addAttribute("metodo", metodo);
        modelo.addAttribute("textoRecibido", valorRecibido);
        modelo.addAttribute("textoCodificado", valorCodificado);
    }

}
