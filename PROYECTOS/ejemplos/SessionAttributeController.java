package com.ejemplo.session;

import com.ejemplo.dominio.Carrito;
import com.ejemplo.dominio.Producto;
import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.math.BigDecimal;

@Controller
public class CarritoController {

    // 1) ATRIBUTO DE SESION: se guarda un OBJETO Carrito en la HttpSession
    @PostMapping("/carrito/agregar")
    public String agregar(@RequestParam Long id,
                          @RequestParam String nombre,
                          @RequestParam BigDecimal precio,
                          @RequestParam(defaultValue = "1") int cantidad,
                          HttpSession session) {
        // Recuperamos el objeto Carrito de la sesion
        Carrito carrito = (Carrito) session.getAttribute("carrito");
        if (carrito == null) {
            carrito = new Carrito();
            session.setAttribute("carrito", carrito); // <-- guardamos el OBJETO en sesion
        }
        carrito.agregar(new Producto(id, nombre, precio, cantidad));
        return "redirect:/carrito";
    }

    @PostMapping("/carrito/eliminar")
    public String eliminar(@RequestParam Long productoId, HttpSession session) {
        Carrito carrito = (Carrito) session.getAttribute("carrito");
        if (carrito != null) {
            carrito.eliminar(productoId);
        }
        return "redirect:/carrito";
    }

    @GetMapping("/carrito")
    public String ver(HttpSession session, Model model) {
        Carrito carrito = (Carrito) session.getAttribute("carrito");
        if (carrito == null) {
            carrito = new Carrito();
            session.setAttribute("carrito", carrito);
        }
        model.addAttribute("carrito", carrito);
        return "carrito";
    }

    @PostMapping("/carrito/vaciar")
    public String vaciar(HttpSession session) {
        session.removeAttribute("carrito"); // eliminamos el atributo de sesion
        return "redirect:/carrito";
    }
}
