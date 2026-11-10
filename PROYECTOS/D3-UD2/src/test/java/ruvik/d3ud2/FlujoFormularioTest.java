package ruvik.d3ud2;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.allOf;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.hasProperty;
import static org.hamcrest.Matchers.is;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.model;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.redirectedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.view;

@SpringBootTest
@AutoConfigureMockMvc
class FlujoFormularioTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void laRaizRedirigeAlPrimerFormulario() throws Exception {
        mockMvc.perform(get("/"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/formulario1"));
    }

    @Test
    void elPrimerFormularioSeRenderiza() throws Exception {
        mockMvc.perform(get("/formulario1"))
                .andExpect(status().isOk())
                .andExpect(view().name("Formulario1"))
                .andExpect(model().attributeExists("datos"))
                .andExpect(content().string(containsString("name=\"contador\"")))
                .andExpect(content().string(containsString("value=\"1\"")));
    }

    @Test
    void avanzaDelPasoUnoAlDosConservandoElNombre() throws Exception {
        mockMvc.perform(post("/procesar")
                        .param("nombre", "Ruvik")
                        .param("contador", "1"))
                .andExpect(status().isOk())
                .andExpect(view().name("Formulario2"))
                .andExpect(model().attribute("contador", 1))
                .andExpect(model().attribute("datos", hasProperty("nombre", is("Ruvik"))));
    }

    @Test
    void avanzaDelPasoDosAlTresConservandoLasAficiones() throws Exception {
        mockMvc.perform(post("/procesar")
                        .param("nombre", "Ruvik")
                        .param("aficciones", "Fútbol")
                        .param("aficciones", "Bádminton")
                        .param("contador", "2"))
                .andExpect(status().isOk())
                .andExpect(view().name("Formulario3"))
                .andExpect(model().attribute("contador", 2))
                .andExpect(model().attribute("datos", allOf(
                        hasProperty("nombre", is("Ruvik")),
                        hasProperty("aficciones", contains("Fútbol", "Bádminton")))))
                .andExpect(content().string(containsString("name=\"aficciones\"")));
    }

    @Test
    void avanzaDelPasoTresAlCuatroConservandoTodosLosDatos() throws Exception {
        mockMvc.perform(post("/procesar")
                        .param("nombre", "Ruvik")
                        .param("aficciones", "Baloncesto")
                        .param("lugar", "Sevilla")
                        .param("contador", "3"))
                .andExpect(status().isOk())
                .andExpect(view().name("Formulario4"))
                .andExpect(model().attribute("contador", 3))
                .andExpect(model().attribute("datos", allOf(
                        hasProperty("nombre", is("Ruvik")),
                        hasProperty("aficciones", contains("Baloncesto")),
                        hasProperty("lugar", is("Sevilla")))));
    }

    @Test
    void elPasoCuatroMuestraElResultadoYNoRedirige() throws Exception {
        mockMvc.perform(post("/procesar")
                        .param("nombre", "Ruvik")
                        .param("aficciones", "Fútbol")
                        .param("aficciones", "Bádminton")
                        .param("lugar", "Málaga")
                        .param("sexo", "M")
                        .param("contador", "4"))
                .andExpect(status().isOk())
                .andExpect(view().name("Resultado"))
                .andExpect(model().attribute("datos", allOf(
                        hasProperty("nombre", is("Ruvik")),
                        hasProperty("aficciones", contains("Fútbol", "Bádminton")),
                        hasProperty("lugar", is("Málaga")),
                        hasProperty("sexo", is("M")))))
                .andExpect(content().string(containsString("Ruvik")))
                .andExpect(content().string(containsString("Málaga")))
                .andExpect(content().string(containsString("Fútbol")));
    }

    @Test
    void elBotonVolverDelPasoDosRegresaAlUnoSinPerderElNombre() throws Exception {
        mockMvc.perform(post("/procesar")
                        .param("nombre", "Ruvik")
                        .param("contador", "-1"))
                .andExpect(status().isOk())
                .andExpect(view().name("Formulario1"))
                .andExpect(model().attribute("datos", hasProperty("nombre", is("Ruvik"))));
    }

    @Test
    void elBotonVolverAlInicioRedirigeAlPrimerFormulario() throws Exception {
        mockMvc.perform(post("/procesar")
                        .param("nombre", "Ruvik")
                        .param("contador", "0"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/formulario1"));
    }
}
