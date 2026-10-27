package br.gov.protege.service;

import br.gov.protege.exception.ArquivoGrandeDemaisException;
import br.gov.protege.exception.FormatoNaoSuportadoException;
import br.gov.protege.exception.RegraDeNegocioException;
import br.gov.protege.model.Evidencia;
import br.gov.protege.repository.EvidenciaRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.mockito.Mockito;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Grava em diretorio temporario de verdade, e nao num mock de sistema de
 * arquivos: metade das garantias aqui - nome gerado, arquivo fora da pasta
 * publica, hash conferido na leitura - so existem quando ha disco envolvido.
 */
@DisplayName("Armazenamento de evidencias")
class EvidenciaServiceTest {

    @TempDir
    Path diretorio;

    private EvidenciaRepository repo;
    private EvidenciaService svc;
    private final List<Evidencia> gravadas = new ArrayList<>();

    /** PNG minimo valido: assinatura correta seguida de conteudo qualquer. */
    private byte[] png(int tamanho) {
        byte[] b = new byte[Math.max(tamanho, 8)];
        int[] marca = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
        for (int i = 0; i < marca.length; i++) b[i] = (byte) marca[i];
        return b;
    }

    @BeforeEach
    void preparar() {
        gravadas.clear();
        repo = Mockito.mock(EvidenciaRepository.class);
        Mockito.when(repo.save(Mockito.any(Evidencia.class))).thenAnswer(inv -> {
            Evidencia e = inv.getArgument(0);
            if (e.getId() == null) e.setId((long) (gravadas.size() + 1));
            gravadas.removeIf(x -> x.getId().equals(e.getId()));
            gravadas.add(e);
            return e;
        });
        Mockito.when(repo.countByDenunciaIdAndRemovidaFalse(Mockito.anyLong()))
               .thenAnswer(inv -> (long) gravadas.size());
        Mockito.when(repo.findByIdAndRemovidaFalse(Mockito.anyLong()))
               .thenAnswer(inv -> gravadas.stream()
                       .filter(e -> e.getId().equals(inv.getArgument(0))).findFirst());

        svc = new EvidenciaService(repo, diretorio.toString());
    }

    @Test
    @DisplayName("o arquivo no disco recebe UUID, e nao o nome enviado pelo usuario")
    void nomeDoUsuarioNaoChegaAoDisco() throws Exception {
        Evidencia ev = svc.guardar(1L, png(64), "../../etc/passwd.png");

        assertEquals("passwd.png", ev.getNomeOriginal(), "o nome exibido perde o caminho");
        assertNotEquals("passwd.png", ev.getNomeArmazenado());
        assertTrue(ev.getNomeArmazenado().matches("[0-9a-f-]{36}"), "deve ser um UUID");

        List<Path> noDisco = Files.list(diretorio).toList();
        assertEquals(1, noDisco.size());
        assertEquals(ev.getNomeArmazenado(), noDisco.get(0).getFileName().toString(),
                "nenhum arquivo com nome do usuario aparece na pasta");
    }

    @Test
    @DisplayName("arquivo acima do limite dá 413, e não 422")
    void arquivoGrandeDemais() {
        byte[] gigante = png((int) EvidenciaService.TAMANHO_MAXIMO + 1);
        assertThrows(ArquivoGrandeDemaisException.class, () -> svc.guardar(1L, gigante, "foto.png"));
        assertEquals(0, gravadas.size(), "nada e gravado quando o arquivo e recusado");
    }

    @Test
    @DisplayName("executável renomeado para .png dá 415")
    void formatoRecusado() {
        byte[] exe = {0x4D, 0x5A, (byte) 0x90, 0x00, 0x03, 0x00, 0x00, 0x00};
        assertThrows(FormatoNaoSuportadoException.class, () -> svc.guardar(1L, exe, "foto.png"));
    }

    @Test
    @DisplayName("arquivo vazio é recusado antes de tocar no disco")
    void arquivoVazio() {
        assertThrows(RegraDeNegocioException.class, () -> svc.guardar(1L, new byte[0], "x.png"));
        assertThrows(RegraDeNegocioException.class, () -> svc.guardar(1L, null, "x.png"));
    }

    @Test
    @DisplayName("o hash grava o SHA-256 do conteúdo recebido")
    void hashDoConteudo() {
        Evidencia ev = svc.guardar(1L, png(32), "a.png");
        assertEquals(64, ev.getHashSha256().length());
        assertEquals(EvidenciaService.sha256(png(32)), ev.getHashSha256());
    }

    @Test
    @DisplayName("arquivo trocado no disco tem a leitura recusada")
    void detectaTrocaNoDisco() throws Exception {
        Evidencia ev = svc.guardar(1L, png(64), "a.png");
        assertArrayEquals(png(64), svc.conteudo(ev), "antes da adulteracao, le normalmente");

        // Alguem com acesso ao disco substitui o arquivo por outro PNG valido.
        Files.write(diretorio.resolve(ev.getNomeArmazenado()), png(128));

        assertThrows(RegraDeNegocioException.class, () -> svc.conteudo(ev),
                "entregar como evidencia um arquivo que nao e mais o recebido "
                + "seria pior do que nao entregar nada");
    }

    @Test
    @DisplayName("teto de arquivos por denúncia é respeitado")
    void limitePorDenuncia() {
        for (int i = 0; i < EvidenciaService.MAXIMO_POR_DENUNCIA; i++) {
            svc.guardar(1L, png(16 + i), "f" + i + ".png");
        }
        assertThrows(RegraDeNegocioException.class, () -> svc.guardar(1L, png(99), "extra.png"));
    }

    @Test
    @DisplayName("remoção apaga o binário e mantém o registro")
    void remocaoLogica() throws Exception {
        Evidencia ev = svc.guardar(1L, png(64), "a.png");
        Path arquivo = diretorio.resolve(ev.getNomeArmazenado());
        assertTrue(Files.exists(arquivo));

        svc.remover(ev.getId(), "duplicado");

        assertFalse(Files.exists(arquivo), "nao ha como anonimizar uma foto: o binario e destruido");
        assertTrue(ev.isRemovida());
        assertEquals("duplicado", ev.getMotivoRemocao());
        assertNotNull(ev.getRemovidaEm(), "o registro fica, com motivo e data");
    }

    @Test
    @DisplayName("Fase 7 | JPEG e gravado sem EXIF/GPS, e o hash e o tamanho sao os da versao limpa")
    void jpegGravadoSemExif() throws Exception {
        byte[] exif = "Exif\0\0GPS-23.5108,-46.8761".getBytes(java.nio.charset.StandardCharsets.ISO_8859_1);
        byte[] cabecalhoApp1 = {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF, (byte) 0xE1, 0, (byte) (exif.length + 2)};
        byte[] imagem = {(byte) 0xFF, (byte) 0xDA, 0, 2, 0x11, 0x22, (byte) 0xFF, (byte) 0xD9};
        byte[] original = new byte[cabecalhoApp1.length + exif.length + imagem.length];
        System.arraycopy(cabecalhoApp1, 0, original, 0, cabecalhoApp1.length);
        System.arraycopy(exif, 0, original, cabecalhoApp1.length, exif.length);
        System.arraycopy(imagem, 0, original, cabecalhoApp1.length + exif.length, imagem.length);

        Evidencia ev = svc.guardar(1L, original, "foto.jpg");

        byte[] noDisco = Files.readAllBytes(diretorio.resolve(ev.getNomeArmazenado()));
        byte[] esperado = {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF, (byte) 0xDA, 0, 2, 0x11, 0x22, (byte) 0xFF, (byte) 0xD9};
        assertArrayEquals(esperado, noDisco, "a copia no disco ja nasce sem o segmento EXIF");
        assertEquals(esperado.length, ev.getTamanhoBytes());
        assertEquals(EvidenciaService.sha256(esperado), ev.getHashSha256());
        assertArrayEquals(esperado, svc.conteudo(ev), "a leitura confere o hash da versao limpa");
    }

    @Test
    @DisplayName("Fase 7 | exclusao da denuncia apaga todos os anexos dela do disco")
    void removerTodasDaDenuncia() throws Exception {
        Evidencia a = svc.guardar(7L, png(32), "a.png");
        Evidencia b = svc.guardar(7L, png(40), "b.png");
        Mockito.when(repo.findByDenunciaIdAndRemovidaFalseOrderByEnviadoEmAsc(7L))
               .thenAnswer(inv -> gravadas.stream().filter(e -> !e.isRemovida()).toList());

        int removidas = svc.removerTodasDa(7L, "Exclusao da denuncia: pedido do titular");

        assertEquals(2, removidas);
        assertFalse(Files.exists(diretorio.resolve(a.getNomeArmazenado())));
        assertFalse(Files.exists(diretorio.resolve(b.getNomeArmazenado())));
        assertTrue(a.isRemovida() && b.isRemovida(), "os registros ficam, marcados como removidos");
        assertEquals("Exclusao da denuncia: pedido do titular", a.getMotivoRemocao());
        assertEquals(0, svc.removerTodasDa(7L, "de novo"), "segunda chamada nao encontra nada");
    }

    @Test
    @DisplayName("remoção sem motivo é recusada")
    void remocaoExigeMotivo() {
        Evidencia ev = svc.guardar(1L, png(32), "a.png");
        assertThrows(RegraDeNegocioException.class, () -> svc.remover(ev.getId(), "  "));
        assertFalse(ev.isRemovida());
    }
}
