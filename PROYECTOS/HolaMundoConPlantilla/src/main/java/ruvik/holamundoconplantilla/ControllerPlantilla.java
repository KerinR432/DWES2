package ruvik.holamundoconplantilla;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Controller
public class ControllerPlantilla {
    @GetMapping("/saludo")
    public String index(@RequestParam(name = "nombre",defaultValue = "mundo cruel")String nombre, Model modelo) {
        modelo.addAttribute("mensaje",nombre);
        return "hola";
    }
}
