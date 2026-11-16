package goya.daw2.pruebas_plantillas;

import java.util.ArrayList;
import java.util.List;

import entity.Quizz;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class FormsController {

	static final String[] SIGNOS = { "", "Aries", "Tauro", "Géminis", "Cáncer", "Leo", "Virgo", "Libra", "Escorpio",
			"Sagitario", "Capricornio", "Acuario", "Piscis" };
	static final String[] AFICCIONES = { "Deportes", "Juerga", "Lectura", "Relaciones sociales" };

	private Quizz getQuizz(HttpSession session) {
		Quizz actual = (Quizz) session.getAttribute("quizz");
		if (actual == null) {
			actual = new Quizz();
			session.setAttribute("quizz", actual);
		}
		return actual;
	}

	private int getEtapa(HttpSession session) {
		Integer etapa = (Integer) session.getAttribute("numEtapa");
		if (etapa == null) {
			etapa = 1;
			session.setAttribute("numEtapa", etapa);
		}
		return etapa;
	}

	@PostMapping("/")
	String procesaEtapaX(Model modelo,
                          Quizz quizz,
                          HttpSession session) {

		Quizz actual = getQuizz(session);
		int numEtapa = getEtapa(session);

		if (quizz.getNombre() != null) {
			actual.setNombre(quizz.getNombre());
		}
		if (quizz.getSigno() != null) {
			actual.setSigno(quizz.getSigno());
		}
		if (quizz.getAficciones() != null && !quizz.getAficciones().isEmpty()) {
			actual.setAficciones(quizz.getAficciones());
		}

		modelo.addAttribute("signos", SIGNOS);
		modelo.addAttribute("aficciones", AFICCIONES);
		modelo.addAttribute("quizz", actual);

		String errores = "";

		if (numEtapa == 1 && (actual.getNombre() == null || actual.getNombre().isBlank())) {
			errores = "Debes poner un nombre no vacío";
		} else if (numEtapa == 1 && (actual.getNombre().length() < 3 || actual.getNombre().length() > 10)) {
			errores = "La longitud del nombre debe estar entre 3 y 10";
		}

		if (numEtapa == 2 && (actual.getSigno() == null || actual.getSigno() == 0)) {
			errores = "Debes seleccionar un signo";
		}

		if (numEtapa == 3 && (actual.getAficciones() == null || actual.getAficciones().isEmpty())) {
			errores = "Debes elegir al menos una aficción, no seas soso/a";
		}

		if (!errores.isBlank()) {
			modelo.addAttribute("errores", errores);
			return "etapa" + numEtapa;
		}

		numEtapa++;
		session.setAttribute("numEtapa", numEtapa);

		if (numEtapa == 4) {
			ArrayList<String> respuestas = new ArrayList<String>();
			respuestas.add(actual.getNombre());
			respuestas.add(SIGNOS[actual.getSigno()]);
			respuestas.add(String.join(", ", actual.getAficciones()));
			modelo.addAttribute("respuestas", respuestas);
		}

		return "etapa" + numEtapa;
	}

	@GetMapping("/")
	String getEtapa0(Model modelo, HttpServletRequest request) {
		HttpSession session = request.getSession(true);
		session.invalidate();
		session = request.getSession(true);
		session.setAttribute("quizz", new Quizz());
		session.setAttribute("numEtapa", 1);
		modelo.addAttribute("quizz", new Quizz());
		modelo.addAttribute("signos", SIGNOS);
		modelo.addAttribute("aficciones", AFICCIONES);
		return "etapa1";
	}
}
