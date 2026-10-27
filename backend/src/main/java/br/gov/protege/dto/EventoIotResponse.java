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
        return de(e, true);
    }

    /**
     * Fase 7 | O evento de SOS guarda onde a vitima estava ao acionar, e o
     * de geofence, a regiao do perimetro protetivo. Para quem nao ve o
     * endereco das denuncias (ATENDENTE), a coordenada sai arredondada a 3
     * casas decimais (cerca de 100 m): serve para saber a regiao do evento,
     * nao para chegar a porta de alguem.
     */
    public static EventoIotResponse de(EventoIot e, boolean coordenadaExata) {
        return new EventoIotResponse(
                e.getId(), e.getOrigem(), e.getDispositivo(),
                coordenadaExata ? e.getLatitude() : arredondar(e.getLatitude()),
                coordenadaExata ? e.getLongitude() : arredondar(e.getLongitude()),
                e.getBateria(),
                e.getSituacao(), e.getProtocoloGerado(), e.getDetalhe(),
                e.getRecebidoEm());
    }

    /** Tres casas decimais. Nulo continua nulo. */
    public static Double arredondar(Double valor) {
        if (valor == null) return null;
        return Math.round(valor * 1000.0) / 1000.0;
    }
}
