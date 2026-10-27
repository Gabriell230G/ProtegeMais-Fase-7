package br.gov.protege.dto;

import br.gov.protege.model.EventoIot;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("Fase 7 | Coordenada dos eventos IoT por perfil")
class EventoIotResponseTest {

    private EventoIot evento() {
        EventoIot e = new EventoIot(EventoIot.SOS, "SOS-0001");
        e.setLatitude(-23.510849);
        e.setLongitude(-46.876143);
        return e;
    }

    @Test
    @DisplayName("GESTOR/ADMIN recebem a coordenada exata")
    void exata() {
        EventoIotResponse r = EventoIotResponse.de(evento(), true);
        assertEquals(-23.510849, r.latitude().doubleValue());
        assertEquals(-46.876143, r.longitude().doubleValue());
    }

    @Test
    @DisplayName("ATENDENTE recebe a coordenada arredondada a 3 casas")
    void arredondada() {
        EventoIotResponse r = EventoIotResponse.de(evento(), false);
        assertEquals(-23.511, r.latitude().doubleValue());
        assertEquals(-46.876, r.longitude().doubleValue());
        assertNull(EventoIotResponse.arredondar(null));
    }
}
