package br.gov.protege.repository;

import br.gov.protege.model.PontoTotem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PontoTotemRepository extends JpaRepository<PontoTotem, Long> {

    /**
     * Um totem desligado nao e um totem inexistente, e a consulta precisa
     * dizer qual dos dois e o caso. Filtrar por ativo aqui garante que um
     * equipamento em manutencao seja recusado pela mesma porta por onde um
     * equipamento desconhecido e recusado.
     */
    Optional<PontoTotem> findByDispositivoAndAtivoTrue(String dispositivo);

    List<PontoTotem> findByAtivoTrue();
}
