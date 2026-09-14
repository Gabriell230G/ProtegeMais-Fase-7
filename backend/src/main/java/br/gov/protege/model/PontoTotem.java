package br.gov.protege.model;

import jakarta.persistence.*;

/**
 * Totem publico instalado em um equipamento do Estado.
 *
 * A decisao central desta origem esta nesta classe: o totem NAO informa onde
 * ele esta. O lugar vem daqui, do cadastro da instalacao.
 *
 * A alternativa seria aceitar a coordenada dentro da requisicao, como o botao
 * de panico faz. Faz sentido no botao, que anda junto com a pessoa e e o unico
 * que sabe onde ela esta. Nao faz sentido num aparelho parafusado numa parede:
 * um totem que pudesse declarar a propria posicao permitiria que alguem com
 * acesso ao equipamento fizesse denuncias aparecerem em qualquer endereco do
 * pais, e o mapa do painel, que e o que orienta o deslocamento das equipes,
 * passaria a ser preenchido por quem tem uma chave de fenda.
 */
@Entity
@Table(name = "ponto_totem")
public class PontoTotem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Identificador opaco do equipamento. Nao identifica pessoa. */
    @Column(unique = true, nullable = false, length = 40)
    private String dispositivo;

    /** Descricao do ponto de instalacao, exibida no painel. */
    @Column(name = "local_instalacao", nullable = false, length = 120)
    private String local;

    @Column(nullable = false, length = 2)
    private String estado;

    @Column(nullable = false, length = 80)
    private String cidade;

    @Column(nullable = false)
    private Double latitude;

    @Column(nullable = false)
    private Double longitude;

    /**
     * Desligar um totem e um ato administrativo, nao uma exclusao.
     *
     * Um equipamento retirado para manutencao precisa parar de aceitar
     * registros sem que os casos ja abertos por ele percam a referencia do
     * lugar onde foram feitos.
     */
    @Column(nullable = false)
    private boolean ativo = true;

    public PontoTotem() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getDispositivo() { return dispositivo; }
    public void setDispositivo(String dispositivo) { this.dispositivo = dispositivo; }

    public String getLocal() { return local; }
    public void setLocal(String local) { this.local = local; }

    public String getEstado() { return estado; }
    public void setEstado(String estado) { this.estado = estado; }

    public String getCidade() { return cidade; }
    public void setCidade(String cidade) { this.cidade = cidade; }

    public Double getLatitude() { return latitude; }
    public void setLatitude(Double latitude) { this.latitude = latitude; }

    public Double getLongitude() { return longitude; }
    public void setLongitude(Double longitude) { this.longitude = longitude; }

    public boolean isAtivo() { return ativo; }
    public void setAtivo(boolean ativo) { this.ativo = ativo; }
}
