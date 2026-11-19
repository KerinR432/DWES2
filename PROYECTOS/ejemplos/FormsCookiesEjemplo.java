package goya.daw2.pruebas_plantillas;

import com.fasterxml.jackson.databind.ObjectMapper;
import entity.Quizz;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseCookie;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.CookieValue;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import java.util.ArrayList;

@Controller
@RequestMapping("/cookies")
public class FormsCookiesEjemplo {

    static final String[] SIGNOS = { "", "Aries", "Tauro", "Géminis", "Cáncer", "Leo", "Virgo", "Libra", "Escorpio",
            "Sagitario", "Capricornio", "Acuario", "Piscis" };
    static final String[] AFICCIONES = { "Deportes", "Juerga", "Lectura", "Relaciones sociales" };

    private final ObjectMapper mapper = new ObjectMapper();

    private Quizz leerCookie(String json) {
        if (json == null || json.isBlank()) return new Quizz();
        try { return mapper.readValue(json, Quizz.class); }
        catch (Exception e) { return new Quizz(); } // cookie corrupta -> estado inicial
    }

    private String escribirCookie(Quizz q) {
        try { return mapper.writeValueAsString(q); }
        catch (Exception e) { return "{}"; }
    }

    private void guardarCookie(HttpServletResponse response, Quizz q) {
        ResponseCookie cookie = ResponseCookie.from("quizz", escribirCookie(q))
                .maxAge(60 * 60 * 24)   // 1 dia
                .path("/")
                .httpOnly(true)
                .sameSite("Lax")
                .build();
        response.addHeader(HttpHeaders.SET_COOKIE, cookie.toString());
    }

    @GetMapping("/quizz")
    String inicio(@CookieValue(name = "quizz", required = false) String cookieVal,
                  Model modelo, HttpServletResponse response) {
        Quizz q = leerCookie(cookieVal);
        q.setNumEtapa(1);
        q.setNombre(null);
        q.setSigno(null);
        q.getAficciones().clear();
        guardarCookie(response, q);

        modelo.addAttribute("quizz", q);
        modelo.addAttribute("signos", SIGNOS);
        modelo.addAttribute("aficciones", AFICCIONES);
        return "etapa1";
    }

    @PostMapping("/quizz")
    String procesa(@CookieValue(name = "quizz", required = false) String cookieVal,
                   Quizz form, Model modelo, HttpServletResponse response) {
        Quizz actual = leerCookie(cookieVal);

        if (form.getNombre() != null) actual.setNombre(form.getNombre());
        if (form.getSigno() != null) actual.setSigno(form.getSigno());
        if (form.getAficciones() != null && !form.getAficciones().isEmpty())
            actual.setAficciones(form.getAficciones());

        if (actual.getNumEtapa() == null) actual.setNumEtapa(1);

        modelo.addAttribute("signos", SIGNOS);
        modelo.addAttribute("aficciones", AFICCIONES);
        modelo.addAttribute("quizz", actual);

        String errores = "";
        if (actual.getNumEtapa() == 1 && (actual.getNombre() == null || actual.getNombre().isBlank()))
            errores = "Debes poner un nombre no vacío";
        else if (actual.getNumEtapa() == 1 && (actual.getNombre().length() < 3 || actual.getNombre().length() > 10))
            errores = "La longitud del nombre debe estar entre 3 y 10";

        if (actual.getNumEtapa() == 2 && (actual.getSigno() == null || actual.getSigno() == 0))
            errores = "Debes seleccionar un signo";

        if (actual.getNumEtapa() == 3 && (actual.getAficciones() == null || actual.getAficciones().isEmpty()))
            errores = "Debes elegir al menos una aficción, no seas soso/a";

        if (!errores.isBlank()) {
            modelo.addAttribute("errores", errores);
            guardarCookie(response, actual);
            return "etapa" + actual.getNumEtapa();
        }

        actual.setNumEtapa(actual.getNumEtapa() + 1);

        if (actual.getNumEtapa() == 4) {
            ArrayList<String> respuestas = new ArrayList<>();
            respuestas.add(actual.getNombre());
            respuestas.add(SIGNOS[actual.getSigno()]);
            respuestas.add(String.join(", ", actual.getAficciones()));
            modelo.addAttribute("respuestas", respuestas);
        }

        guardarCookie(response, actual);
        return "etapa" + actual.getNumEtapa();
    }
}
