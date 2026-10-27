package ruvik.d4ud2.controllador;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
public class I18Controller {
    @GetMapping("/i18n")
    public String mostrarI18n() {
        return "mostrarI18n";
    }
}
