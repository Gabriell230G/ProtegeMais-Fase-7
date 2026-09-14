package br.gov.protege;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.TestPropertySource;

/**
 * Teste de fumaca: a aplicacao sobe?
 *
 * Este arquivo nasceu de um defeito real. O projeto tinha 116 testes
 * passando e a aplicacao nao subia: uma entidade declarava precision e
 * scale sobre um campo Double, e o Hibernate 6 recusa escala em tipo de
 * ponto flutuante. Nenhum dos 116 testes percebeu, porque todos eram
 * unitarios e nenhum carregava o contexto do Spring. O erro so aparecia
 * ao rodar a aplicacao, que e exatamente o que um avaliador faz primeiro.
 *
 * Uma suite que so testa regras de negocio testa o que o programador
 * escreveu e ignora o que o framework precisa. Este teste cobre a costura
 * entre os dois: mapeamento das entidades, criacao do schema, execucao do
 * data.sql e montagem de todos os beans.
 *
 * Roda em banco de memoria, e nao no arquivo de demonstracao, para que a
 * suite nunca altere os dados que a apresentacao vai usar.
 */
@SpringBootTest
@TestPropertySource(properties = {
        "spring.datasource.url=jdbc:h2:mem:fumaca;DB_CLOSE_DELAY=-1",
        "spring.datasource.driver-class-name=org.h2.Driver",
        "spring.datasource.username=sa",
        "spring.datasource.password=",
        "spring.jpa.hibernate.ddl-auto=create-drop",
        "spring.sql.init.mode=always",
        "gemini.api.key="
})
class ContextoSobeTest {

    @Test
    @DisplayName("o contexto do Spring carrega inteiro, com schema e carga inicial")
    void contextoCarrega() {
        // Sem asserts de proposito. A falha deste teste e a excecao lancada
        // durante a montagem do contexto, e a mensagem dela e o diagnostico.
    }
}
