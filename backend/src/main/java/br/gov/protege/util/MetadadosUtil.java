package br.gov.protege.util;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.Set;

/**
 * Fase 7 | Remocao de metadados de imagem antes de gravar a evidencia.
 *
 * A foto anexada a uma denuncia costuma trazer, no EXIF, a coordenada GPS e
 * o horario exatos de onde foi tirada, alem do modelo do aparelho. O
 * ATENDENTE, que por projeto nao ve o endereco da vitima, receberia essa
 * localizacao baixando o arquivo. A limpeza acontece na GRAVACAO: a copia
 * no disco ja nasce sem metadado, e o hash da cadeia de custodia e
 * calculado sobre a versao limpa.
 *
 * Nada e recodificado: os pixels e os blocos necessarios para exibir a
 * imagem sao copiados byte a byte. Recodificar (ImageIO) perderia qualidade
 * e alteraria a evidencia alem do necessario.
 *
 *  JPEG: remove os segmentos APP1..APP15 (EXIF, XMP, ICC, Photoshop/IPTC,
 *        etc.) e COM. Mantem APP0 (JFIF) e todos os segmentos de imagem. A
 *        partir do SOS (inicio dos dados comprimidos) o restante e copiado
 *        sem alteracao.
 *  PNG:  remove os blocos tEXt, zTXt, iTXt, eXIf e tIME. Os demais blocos
 *        sao copiados inteiros, com o CRC original.
 *
 * Outros formatos (PDF, audio, video, WebP) passam sem alteracao: o
 * tratamento deles exigiria parser proprio e fica registrado como pendencia.
 *
 * Arquivo malformado (segmento que nao fecha, estrutura truncada) volta
 * como veio: a regra aqui e nunca corromper uma evidencia. Classe pura, sem
 * dependencia de Spring, para ser testada com bytes montados no teste.
 */
public final class MetadadosUtil {

    private MetadadosUtil() { }

    /** Blocos PNG de texto livre, metadado EXIF e data de modificacao. */
    static final Set<String> BLOCOS_PNG_REMOVIDOS = Set.of("tEXt", "zTXt", "iTXt", "eXIf", "tIME");

    private static final byte[] ASSINATURA_PNG =
            {(byte) 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};

    /**
     * Devolve o conteudo sem metadados, conforme o tipo ja detectado pela
     * assinatura do arquivo. Para tipos sem tratamento, devolve o proprio
     * array recebido.
     */
    public static byte[] remover(byte[] dados, String tipo) {
        if (dados == null || tipo == null) return dados;
        if ("image/jpeg".equals(tipo)) return limparJpeg(dados);
        if ("image/png".equals(tipo)) return limparPng(dados);
        return dados;
    }

    // ------------------------------------------------------------------
    //  JPEG
    // ------------------------------------------------------------------

    /** Remove APP1..APP15 e COM; copia o restante sem tocar nos dados da imagem. */
    public static byte[] limparJpeg(byte[] d) {
        int n = d.length;
        if (n < 4 || u(d[0]) != 0xFF || u(d[1]) != 0xD8) return d;

        ByteArrayOutputStream out = new ByteArrayOutputStream(n);
        out.write(0xFF);
        out.write(0xD8);
        int i = 2;
        boolean removeu = false;

        while (i < n) {
            if (u(d[i]) != 0xFF) return d;              // esperava um marcador
            // Bytes 0xFF repetidos antes do codigo do marcador sao preenchimento.
            while (i < n && u(d[i]) == 0xFF) i++;
            if (i >= n) return d;
            int marcador = u(d[i]);
            i++;
            if (marcador == 0x00) return d;             // 0xFF00 so existe dentro do scan

            if (marcador == 0xDA) {
                // SOS: dali em diante vem a imagem comprimida. Copia tudo.
                out.write(0xFF);
                out.write(0xDA);
                out.write(d, i, n - i);
                return removeu ? out.toByteArray() : d;
            }
            if (marcador == 0xD9) {
                // EOI antes do SOS: imagem sem dados. Copia o restante e encerra.
                out.write(0xFF);
                out.write(0xD9);
                out.write(d, i, n - i);
                return removeu ? out.toByteArray() : d;
            }
            if (marcador == 0x01 || (marcador >= 0xD0 && marcador <= 0xD7)) {
                // Marcadores sem tamanho (TEM, RSTn).
                out.write(0xFF);
                out.write(marcador);
                continue;
            }

            if (i + 2 > n) return d;
            int tamanho = (u(d[i]) << 8) | u(d[i + 1]);   // inclui os 2 bytes do proprio tamanho
            if (tamanho < 2 || i + tamanho > n) return d;

            boolean metadado = (marcador >= 0xE1 && marcador <= 0xEF) || marcador == 0xFE;
            if (metadado) {
                removeu = true;
            } else {
                out.write(0xFF);
                out.write(marcador);
                out.write(d, i, tamanho);
            }
            i += tamanho;
        }
        // Acabou sem SOS: estrutura incompleta, devolve o original.
        return d;
    }

    // ------------------------------------------------------------------
    //  PNG
    // ------------------------------------------------------------------

    /** Remove blocos de texto, EXIF e data; mantem os demais com o CRC original. */
    public static byte[] limparPng(byte[] d) {
        int n = d.length;
        if (n < ASSINATURA_PNG.length) return d;
        for (int k = 0; k < ASSINATURA_PNG.length; k++) {
            if (d[k] != ASSINATURA_PNG[k]) return d;
        }

        ByteArrayOutputStream out = new ByteArrayOutputStream(n);
        out.write(d, 0, ASSINATURA_PNG.length);
        int i = ASSINATURA_PNG.length;
        boolean removeu = false;

        while (i < n) {
            if (i + 8 > n) return d;                     // cabecalho do bloco incompleto
            long tamanho = ((long) u(d[i]) << 24) | (u(d[i + 1]) << 16) | (u(d[i + 2]) << 8) | u(d[i + 3]);
            long total = 12L + tamanho;                  // tamanho + tipo + dados + CRC
            if (tamanho > Integer.MAX_VALUE || i + total > n) return d;
            String tipo = new String(d, i + 4, 4, StandardCharsets.ISO_8859_1);

            if (BLOCOS_PNG_REMOVIDOS.contains(tipo)) {
                removeu = true;
            } else {
                out.write(d, i, (int) total);
            }
            i += (int) total;
            if ("IEND".equals(tipo)) {
                // Nada depois do IEND faz parte da imagem; bytes extras ali
                // seriam um esconderijo de metadado.
                if (i < n) removeu = true;
                break;
            }
        }
        return removeu ? out.toByteArray() : d;
    }

    private static int u(byte b) {
        return b & 0xFF;
    }
}
