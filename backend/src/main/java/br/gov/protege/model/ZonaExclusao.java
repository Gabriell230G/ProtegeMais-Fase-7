package br.gov.protege.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * Area de exclusao de uma medida protetiva.
 *
 * Aqui mora a decisao mais importante do modulo de geofencing: o perimetro
 * pertence ao SERVIDOR, nunca ao dispositivo. A tornozeleira informa apenas
 * onde ela esta; quem sabe onde a vitima mora, qual o raio e se a medida
 * continua valida e o banco.
 *
 * A alternativa seria mandar o perimetro para o aparelho e deixar que ele
 * mesmo avaliasse a violacao, o que pouparia trafego. Seria tambem entregar
 * a coordenada da vitima a um equipamento que esta, por definicao, na posse
 * da pessoa contra quem a medida foi expedida.
 */
@Entity
@Table(name = "zona_exclusao")
public class ZonaExclusao {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Numero do processo judicial que expediu a medida. */
    @Column(nullable = false, length = 30)
    private String processo;

    /** Identificador do equipamento de monitoracao vinculado a medida. */
    @Column(unique = true, nullable = false, length = 40)
    private String tornozeleira;

    @Column(name = "lat_protegida", nullable = false)
    private Double latProtegida;

    @Column(name = "lng_protegida", nullable = false)
    private Double lngProtegida;

    /** Raio em metros. O padrao de 500 m acompanha o usual das medidas. */
    @Column(name = "raio_metros", nullable = false)
    private Integer raioMetros = 500;

    @Column(nullable = false)
    private boolean ativa = true;

    /**
     * Estado da ultima avaliacao.
     *
     * Sem guardar isto, cada ping recebido enquanto o agressor permanece
     * dentro do perimetro abriria um caso novo. Em telemetria de 30 em 30
     * segundos, uma hora de violacao viraria 120 denuncias do mesmo fato.
     */
    @Column(name = "dentro_do_perimetro", nullable = false)
    private boolean dentroDoPerimetro = false;

    @Column(name = "ultimo_alerta_em")
    private LocalDateTime ultimoAlertaEm;

    public ZonaExclusao() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getProcesso() { return processo; }
    public void setProcesso(String processo) { this.processo = processo; }

    public String getTornozeleira() { return tornozeleira; }
    public void setTornozeleira(String tornozeleira) { this.tornozeleira = tornozeleira; }

    public Double getLatProtegida() { return latProtegida; }
    public void setLatProtegida(Double latProtegida) { this.latProtegida = latProtegida; }

    public Double getLngProtegida() { return lngProtegida; }
    public void setLngProtegida(Double lngProtegida) { this.lngProtegida = lngProtegida; }

    public Integer getRaioMetros() { return raioMetros; }
    public void setRaioMetros(Integer raioMetros) { this.raioMetros = raioMetros; }

    public boolean isAtiva() { return ativa; }
    public void setAtiva(boolean ativa) { this.ativa = ativa; }

    public boolean isDentroDoPerimetro() { return dentroDoPerimetro; }
    public void setDentroDoPerimetro(boolean dentroDoPerimetro) { this.dentroDoPerimetro = dentroDoPerimetro; }

    public LocalDateTime getUltimoAlertaEm() { return ultimoAlertaEm; }
    public void setUltimoAlertaEm(LocalDateTime ultimoAlertaEm) { this.ultimoAlertaEm = ultimoAlertaEm; }
}
