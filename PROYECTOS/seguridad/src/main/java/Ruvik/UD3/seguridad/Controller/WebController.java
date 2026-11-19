package Ruvik.UD3.seguridad.Controller;

import Ruvik.UD3.seguridad.Entity.Usuario;
import jakarta.servlet.http.HttpSession;
import org.springframework.boot.web.server.servlet.Session;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Controller
@SessionAttributes("usuario")
public class WebController {
    Map<String,String> usuarioValidos = Map.of(
            "admin","1234",
            "ruvik","b432"
    );

    @GetMapping("/")
    public String rutaInicio(HttpSession session) {
        Usuario user = (Usuario) session.getAttribute("usuario");
        System.out.println("Estoy dentro de inicio");
        if (user==null){
            System.out.println("No existe usuario");
            return "redirect:/login";
        }
        return "inicio";
    }

    @GetMapping("/pagina1")
    public String pagina1(HttpSession session) {
        Usuario user = (Usuario) session.getAttribute("usuario");
        System.out.println("Estoy dentro de pagina 1");
        if (user==null){
            System.out.println("No existe usuario");
            return "redirect:/login";
        }
        return "pagina1";
    }


    @GetMapping("/pagina2")
    public String pagina2(HttpSession session) {
        Usuario user = (Usuario) session.getAttribute("usuario");
        System.out.println("Estoy dentro de pagina 2");
        if (user==null){
            System.out.println("No existe usuario");
            return "redirect:/login";
        }
        return "pagina2";
    }

    @GetMapping("/login")
    public String login(HttpSession sesion, Model modelo) {
        System.out.println("Estoy dentro de login");
        if(sesion.getAttribute("usuario") != null) {
            System.out.println("existe nombre");
            return "redirect:/";
        }
        modelo.addAttribute("usuario", new Usuario());
        return "login";
    }

    @PostMapping("/login")
    public String procesarLogin(@ModelAttribute Usuario usuarioForm,HttpSession sesion, Model modelo) {
        System.out.println("el usuario es: " + usuarioForm.getNombre());
        System.out.printf("El valido usuario es: " + usuarioValidos.get("admin"));
        System.out.println("La contraseña usuario es: " + usuarioForm.getContraseña());
        System.out.printf("La contraseña valida " + usuarioValidos.get("1234"));
        if (usuarioForm.getContraseña().equals( usuarioValidos.get(usuarioForm.getNombre()))) {
            sesion.setAttribute("usuario",usuarioForm);
            return "redirect:/";
        }
        return "login";
    }
    @GetMapping("/logout")
    public String logout(HttpSession sesion, Model modelo) {
        sesion.invalidate();
        return "redirect:/login";
    }

}
