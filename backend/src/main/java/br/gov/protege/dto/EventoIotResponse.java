package br.gov.protege.dto;

import br.gov.protege.model.EventoIot;
import java.time.LocalDateTime;

/**
 * Saida publica de um evento de IoT para o painel do orgao.
 *
 * Devolve coordenada e aparelho, nunca a pessoa vinculada. Quem precisa
 * do caso segue pelo protocolo, e essa leitura ja e auditada.
 */
public record EventoIotResponse(
        Long id,
        String origem,
        String dispositivo,
        Double latitude,
        Double longitude,
        Integer bateria,
        String situacao,
        String protocoloGerado,
        String detalhe,
        LocalDateTime recebidoEm) {

    public static EventoIotResponse de(EventoIot e) {
        return new EventoIotResponse(
                e.getId(), e.getOrigem(), e.getDispositivo(),
                e.getLatitude(), e.getLongitude(), e.getBateria(),
                e.getSituacao(), e.getProtocoloGerado(), e.getDetalhe(),
                e.getRecebidoEm());
    }
}
