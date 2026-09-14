package br.gov.protege.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * Um evento recebido de um dispositivo fisico.
 *
 * A Fase 6 acrescenta ao Protege+ um barramento de eventos de IoT. Em vez de
 * criar uma integracao por tipo de aparelho, existe UMA tabela e UM contrato:
 * o dispositivo manda o que observou, o servidor decide o que fazer. As tres
 * origens previstas (botao de panico, tornozeleira com geofencing e totem em
 * unidade publica) diferem apenas no campo `origem` e no detalhe.
 *
 * A escolha tem uma consequencia de privacidade que vale registrar: o evento
 * guarda o identificador do APARELHO, nunca o da pessoa. O vinculo entre o
 * aparelho e o caso vive no servidor, protegido pelas mesmas regras de acesso
 * do resto do sistema, e nunca trafega ate o dispositivo.
 */
@Entity
@Table(name = "evento_iot")
public class EventoIot {

    /** Origens previstas. Conferidas pelo CHECK ck_evento_iot_origem. */
    public static final String SOS      = "SOS";
    public static final String GEOFENCE = "GEOFENCE";
    public static final String TOTEM    = "TOTEM";

    /** Situacoes possiveis apos o processamento. */
    public static final String ACEITO     = "ACEITO";
    public static final String DUPLICADO  = "DUPLICADO";
    public static final String DESCARTADO = "DESCARTADO";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 10)
    private String origem;

    /** Identificador opaco do aparelho. Nao identifica pessoa. */
    @Column(nullable = false, length = 40)
    private String dispositivo;

    /**
     * Coordenada em ponto flutuante.
     *
     * Sem precision nem scale: escala e um conceito de tipo decimal exato, e
     * declara-la sobre um Double faz o Hibernate 6 recusar o mapeamento na
     * subida da aplicacao. A precisao de seis casas, que e o que interessa
     * para uma coordenada WGS 84, esta declarada onde ela de fato vale, no
     * NUMBER(9,6) do modelo fisico em database/04_ddl_fase6.sql.
     */
    @Column
    private Double latitude;

    @Column
    private Double longitude;

    /** Percentual de bateria informado pelo aparelho, quando houver. */
    private Integer bateria;

    @Column(name = "recebido_em", nullable = false)
    private LocalDateTime recebidoEm = LocalDateTime.now();

    @Column(nullable = false, length = 12)
    private String situacao = ACEITO;

    /** Protocolo da denuncia aberta por este evento, quando houver. */
    @Column(name = "protocolo_gerado", length = 20)
    private String protocoloGerado;

    /** Texto curto e NAO sensivel sobre o evento. */
    @Column(length = 200)
    private String detalhe;

    public EventoIot() {}

    public EventoIot(String origem, String dispositivo) {
        this.origem = origem;
        this.dispositivo = dispositivo;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getOrigem() { return origem; }
    public void setOrigem(String origem) { this.origem = origem; }

    public String getDispositivo() { return dispositivo; }
    public void setDispositivo(String dispositivo) { this.dispositivo = dispositivo; }

    public Double getLatitude() { return latitude; }
    public void setLatitude(Double latitude) { this.latitude = latitude; }

    public Double getLongitude() { return longitude; }
    public void setLongitude(Double longitude) { this.longitude = longitude; }

    public Integer getBateria() { return bateria; }
    public void setBateria(Integer bateria) { this.bateria = bateria; }

    public LocalDateTime getRecebidoEm() { return recebidoEm; }
    public void setRecebidoEm(LocalDateTime recebidoEm) { this.recebidoEm = recebidoEm; }

    public String getSituacao() { return situacao; }
    public void setSituacao(String situacao) { this.situacao = situacao; }

    public String getProtocoloGerado() { return protocoloGerado; }
    public void setProtocoloGerado(String protocoloGerado) { this.protocoloGerado = protocoloGerado; }

    public String getDetalhe() { return detalhe; }
    public void setDetalhe(String detalhe) { this.detalhe = detalhe; }
}
