package ruvik.carritocompragemini;

import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@Controller
@RequestMapping("/tienda")
public class TiendaController {

    private static final List<Producto> CATALOGO = Arrays.asList(
            new Producto(1L, "Portátil Gaming", 899.99),
            new Producto(2L, "Ratón Inalámbrico", 25.50),
            new Producto(3L, "Teclado Mecánico", 75.00)
    );

    @GetMapping("/productos")
    public String listarProductos(Model model) {
        model.addAttribute("productos", CATALOGO);
        return "productos";
    }

    @PostMapping("/carrito/agregar/{id}")
    public String agregarAlCarrito(@PathVariable Long id, HttpSession session) {

        @SuppressWarnings("unchecked")
        Map<Producto, Integer> carrito = (Map<Producto, Integer>) session.getAttribute("carrito");

        if (carrito == null) {
            carrito = new HashMap<>();
        }

        Producto productoSeleccionado = CATALOGO.stream()
                .filter(p -> p.getId().equals(id))
                .findFirst()
                .orElse(null);

        if (productoSeleccionado != null) {
            int cantidadActual = carrito.getOrDefault(productoSeleccionado, 0);
            carrito.put(productoSeleccionado, cantidadActual + 1);
        }

        session.setAttribute("carrito", carrito);

        return "redirect:/tienda/carrito";
    }

    @GetMapping("/carrito")
    public String verCarrito(HttpSession session, Model model) {
        @SuppressWarnings("unchecked")
        Map<Producto, Integer> carrito = (Map<Producto, Integer>) session.getAttribute("carrito");

        if (carrito == null) {
            carrito = new HashMap<>();
        }

        double total = carrito.entrySet().stream()
                .mapToDouble(entry -> entry.getKey().getPrecio() * entry.getValue())
                .sum();

        model.addAttribute("carrito", carrito);
        model.addAttribute("total", total);

        return "carrito";
    }

    @GetMapping("/carrito/vaciar")
    public String vaciarCarrito(HttpSession session) {
        session.removeAttribute("carrito");
        return "redirect:/tienda/productos";
    }
}
