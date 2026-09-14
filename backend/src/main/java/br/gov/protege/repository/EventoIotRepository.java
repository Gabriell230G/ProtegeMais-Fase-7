package br.gov.protege.repository;

import br.gov.protege.model.EventoIot;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface EventoIotRepository extends JpaRepository<EventoIot, Long> {

    /** Ultimo evento aceito daquele aparelho. Base da regra de repique. */
    Optional<EventoIot> findFirstByDispositivoAndSituacaoOrderByRecebidoEmDesc(
            String dispositivo, String situacao);

    Page<EventoIot> findAllByOrderByRecebidoEmDesc(Pageable pageable);

    @Query("SELECT e FROM EventoIot e WHERE (:origem IS NULL OR e.origem = :origem) "
         + "ORDER BY e.recebidoEm DESC")
    List<EventoIot> listarPorOrigem(@Param("origem") String origem, Pageable pageable);

    long countByOrigem(String origem);
}
