package Ruvik.UD3.seguridad.Controller;

import Ruvik.UD3.seguridad.Entity.Usuario;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.bind.support.SessionStatus;

import java.util.HashMap;
import java.util.Map;

@Controller
@SessionAttributes("usuario")
public class WebController {
    private final PasswordEncoder passwordEncoder = new BCryptPasswordEncoder();
    private final Map<String, String> usuariosValidos;
    public WebController() {
        usuariosValidos = new HashMap<>();
        usuariosValidos.put("admin", passwordEncoder.encode("1234"));
        usuariosValidos.put("ruvik", passwordEncoder.encode("b432"));
    }


    @GetMapping("/")
    public String rutaInicio(Model model) {
        if (model.getAttribute("usuario") == null) {
            return "redirect:/login";
        }
        return "inicio";
    }

    @GetMapping("/pagina1")
    public String pagina1(Model model) {
        if (model.getAttribute("usuario") == null) {
            return "redirect:/login";
        }
        return "pagina1";
    }


    @GetMapping("/pagina2")
    public String pagina2(Model model) {
        if (model.getAttribute("usuario") == null) {
            return "redirect:/login";
        }
        return "pagina2";
    }

    @GetMapping("/login")
    public String login(Model model) {
        if (model.getAttribute("usuario") != null) {
            return "redirect:/";
        }
        model.addAttribute("usuarioForm", new Usuario());
        return "login";
    }

    @PostMapping("/login")
    public String procesarLogin(@ModelAttribute("usuarioForm") Usuario usuarioForm, Model model) {
        String hash = usuariosValidos.get(usuarioForm.getNombre());
        if (hash != null && passwordEncoder.matches(usuarioForm.getContraseña(), hash)) {
            model.addAttribute("usuario", usuarioForm);
            return "redirect:/";
        }
        model.addAttribute("error", "Usuario o contraseña son incorrectos");
        Usuario form = new Usuario();
        form.setNombre(usuarioForm.getNombre());
        model.addAttribute("usuarioForm", form);
        return "login";
    }

    @GetMapping("/logout")
    public String logout(SessionStatus status) {
        status.setComplete();
        return "redirect:/login";
    }

}