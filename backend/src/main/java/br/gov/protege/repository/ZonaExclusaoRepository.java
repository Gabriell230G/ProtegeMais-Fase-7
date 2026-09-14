package br.gov.protege.repository;

import br.gov.protege.model.ZonaExclusao;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ZonaExclusaoRepository extends JpaRepository<ZonaExclusao, Long> {

    Optional<ZonaExclusao> findByTornozeleiraAndAtivaTrue(String tornozeleira);

    List<ZonaExclusao> findByAtivaTrue();
}
