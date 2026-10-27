package br.gov.protege.util;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.zip.CRC32;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Fase 7 | Os arquivos sao montados byte a byte aqui no teste, para que cada
 * segmento e cada bloco tenha conteudo conhecido e a verificacao seja exata.
 */
@DisplayName("Fase 7 | Remocao de metadados de imagem")
class MetadadosUtilTest {

    // ------------------------------------------------------------------
    //  Montagem de JPEG
    // ------------------------------------------------------------------

    private static byte[] segmento(int marcador, byte[] corpo) {
        int tamanho = corpo.length + 2;
        byte[] s = new byte[corpo.length + 4];
        s[0] = (byte) 0xFF;
        s[1] = (byte) marcador;
        s[2] = (byte) (tamanho >> 8);
        s[3] = (byte) tamanho;
        System.arraycopy(corpo, 0, s, 4, corpo.length);
        return s;
    }

    private static byte[] juntar(byte[]... partes) {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        for (byte[] p : partes) out.write(p, 0, p.length);
        return out.toByteArray();
    }

    private static byte[] ascii(String s) {
        return s.getBytes(StandardCharsets.ISO_8859_1);
    }

    private static boolean contem(byte[] dados, String trecho) {
        return new String(dados, StandardCharsets.ISO_8859_1).contains(trecho);
    }

    private static final byte[] SOI = {(byte) 0xFF, (byte) 0xD8};
    private static final byte[] APP0 = segmento(0xE0, ascii("JFIF\0\1\1\0\0\1\0\1\0\0"));
    private static final byte[] APP1_EXIF = segmento(0xE1, ascii("Exif\0\0GPS-23.5108,-46.8761"));
    private static final byte[] APP13_IPTC = segmento(0xED, ascii("Photoshop 3.0\0autor=Fulano"));
    private static final byte[] COM = segmento(0xFE, ascii("comentario secreto"));
    private static final byte[] DQT = segmento(0xDB, new byte[65]);
    private static final byte[] SOF0 = segmento(0xC0, new byte[]{8, 0, 1, 0, 1, 1, 1, 0x11, 0});
    /** SOS seguido de dados comprimidos com 0xFF00, um RST e o EOI. */
    private static final byte[] SCAN = juntar(
            segmento(0xDA, new byte[]{1, 1, 0, 0, 0x3F, 0}),
            new byte[]{0x12, (byte) 0xFF, 0x00, 0x34, (byte) 0xFF, (byte) 0xD0, 0x56,
                       (byte) 0xFF, (byte) 0xE1, (byte) 0xFF, (byte) 0xD9});

    @Test
    @DisplayName("JPEG: APP1 (EXIF/GPS), APP13 e COM saem; APP0 e a imagem ficam intactos")
    void jpegSemExif() {
        byte[] original = juntar(SOI, APP0, APP1_EXIF, APP13_IPTC, COM, DQT, SOF0, SCAN);

        byte[] limpo = MetadadosUtil.remover(original, "image/jpeg");

        assertArrayEquals(juntar(SOI, APP0, DQT, SOF0, SCAN), limpo);
        assertFalse(contem(limpo, "GPS"));
        assertFalse(contem(limpo, "Fulano"));
        assertFalse(contem(limpo, "secreto"));
        assertTrue(contem(limpo, "JFIF"), "APP0 (JFIF) e mantido");
    }

    @Test
    @DisplayName("JPEG: bytes 0xFF de preenchimento antes do marcador sao tolerados")
    void jpegComPreenchimento() {
        byte[] preenchido = juntar(new byte[]{(byte) 0xFF, (byte) 0xFF}, APP1_EXIF);
        byte[] original = juntar(SOI, APP0, preenchido, DQT, SCAN);

        assertArrayEquals(juntar(SOI, APP0, DQT, SCAN), MetadadosUtil.remover(original, "image/jpeg"));
    }

    @Test
    @DisplayName("JPEG: depois do SOS tudo e copiado sem alteracao, inclusive 0xFFE1 dentro do scan")
    void jpegScanIntacto() {
        byte[] original = juntar(SOI, APP1_EXIF, DQT, SCAN);
        byte[] limpo = MetadadosUtil.remover(original, "image/jpeg");

        byte[] fim = Arrays.copyOfRange(limpo, limpo.length - SCAN.length, limpo.length);
        assertArrayEquals(SCAN, fim);
    }

    @Test
    @DisplayName("JPEG sem metadado volta como veio; JPEG truncado tambem")
    void jpegSemMudanca() {
        byte[] semMetadado = juntar(SOI, APP0, DQT, SCAN);
        assertSame(semMetadado, MetadadosUtil.remover(semMetadado, "image/jpeg"));

        byte[] truncado = Arrays.copyOf(juntar(SOI, APP1_EXIF, DQT), 30);
        assertSame(truncado, MetadadosUtil.remover(truncado, "image/jpeg"),
                "estrutura que nao fecha nao e reescrita: a evidencia nunca e corrompida");
    }

    @Test
    @DisplayName("JPEG real gerado pelo ImageIO continua legivel depois da limpeza")
    void jpegRealContinuaLegivel() throws Exception {
        BufferedImage img = new BufferedImage(8, 6, BufferedImage.TYPE_INT_RGB);
        img.setRGB(1, 1, 0xFF0000);
        ByteArrayOutputStream buf = new ByteArrayOutputStream();
        assertTrue(ImageIO.write(img, "jpg", buf));
        byte[] gerado = buf.toByteArray();

        // Insere EXIF e comentario logo depois do SOI.
        byte[] comExif = juntar(SOI, APP1_EXIF, COM, Arrays.copyOfRange(gerado, 2, gerado.length));
        byte[] limpo = MetadadosUtil.remover(comExif, "image/jpeg");

        assertArrayEquals(gerado, limpo, "sem os segmentos inseridos, volta ao arquivo gerado");
        BufferedImage lida = ImageIO.read(new ByteArrayInputStream(limpo));
        assertNotNull(lida);
        assertEquals(8, lida.getWidth());
        assertEquals(6, lida.getHeight());
    }

    // ------------------------------------------------------------------
    //  Montagem de PNG
    // ------------------------------------------------------------------

    private static final byte[] ASSINATURA_PNG =
            {(byte) 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};

    private static byte[] bloco(String tipo, byte[] dados) {
        byte[] t = ascii(tipo);
        CRC32 crc = new CRC32();
        crc.update(t);
        crc.update(dados);
        long c = crc.getValue();
        int n = dados.length;
        return juntar(new byte[]{(byte) (n >>> 24), (byte) (n >>> 16), (byte) (n >>> 8), (byte) n},
                t, dados,
                new byte[]{(byte) (c >>> 24), (byte) (c >>> 16), (byte) (c >>> 8), (byte) c});
    }

    @Test
    @DisplayName("PNG: tEXt, zTXt, iTXt, eXIf e tIME saem; os demais blocos ficam com o CRC original")
    void pngSemTexto() {
        byte[] ihdr = bloco("IHDR", new byte[]{0, 0, 0, 1, 0, 0, 0, 1, 8, 2, 0, 0, 0});
        byte[] idat = bloco("IDAT", new byte[]{0x78, 0x01, 0x01, 0x02, 0x00});
        byte[] iend = bloco("IEND", new byte[0]);
        byte[] original = juntar(ASSINATURA_PNG, ihdr,
                bloco("tEXt", ascii("Author\0Fulano de Tal")),
                bloco("eXIf", ascii("MM\0*GPS-23.51")),
                bloco("tIME", new byte[]{0x07, (byte) 0xEA, 10, 27, 12, 0, 0}),
                bloco("zTXt", ascii("Comment\0\0xx")),
                bloco("iTXt", ascii("XML:com.adobe.xmp\0\0\0\0\0<x/>")),
                idat, iend);

        byte[] limpo = MetadadosUtil.remover(original, "image/png");

        assertArrayEquals(juntar(ASSINATURA_PNG, ihdr, idat, iend), limpo);
        assertFalse(contem(limpo, "Fulano"));
        assertFalse(contem(limpo, "GPS"));
    }

    @Test
    @DisplayName("PNG: bytes depois do IEND sao descartados")
    void pngSemCauda() {
        byte[] ihdr = bloco("IHDR", new byte[]{0, 0, 0, 1, 0, 0, 0, 1, 8, 2, 0, 0, 0});
        byte[] iend = bloco("IEND", new byte[0]);
        byte[] original = juntar(ASSINATURA_PNG, ihdr, iend, ascii("GPS escondido"));

        assertArrayEquals(juntar(ASSINATURA_PNG, ihdr, iend), MetadadosUtil.remover(original, "image/png"));
    }

    @Test
    @DisplayName("PNG sem metadado e PNG malformado voltam como vieram")
    void pngSemMudanca() {
        byte[] ihdr = bloco("IHDR", new byte[]{0, 0, 0, 1, 0, 0, 0, 1, 8, 2, 0, 0, 0});
        byte[] limpoDeOrigem = juntar(ASSINATURA_PNG, ihdr, bloco("IEND", new byte[0]));
        assertSame(limpoDeOrigem, MetadadosUtil.remover(limpoDeOrigem, "image/png"));

        byte[] truncado = Arrays.copyOf(juntar(ASSINATURA_PNG, ihdr, bloco("tEXt", ascii("a\0b"))), 40);
        assertSame(truncado, MetadadosUtil.remover(truncado, "image/png"));
    }

    @Test
    @DisplayName("PNG real gerado pelo ImageIO continua legivel depois da limpeza")
    void pngRealContinuaLegivel() throws Exception {
        BufferedImage img = new BufferedImage(5, 4, BufferedImage.TYPE_INT_ARGB);
        img.setRGB(2, 2, 0xFF00FF00);
        ByteArrayOutputStream buf = new ByteArrayOutputStream();
        assertTrue(ImageIO.write(img, "png", buf));
        byte[] gerado = buf.toByteArray();

        // Insere um tEXt logo depois do IHDR (8 de assinatura + 25 do IHDR).
        byte[] comTexto = juntar(Arrays.copyOfRange(gerado, 0, 33),
                bloco("tEXt", ascii("Location\0-23.5108,-46.8761")),
                Arrays.copyOfRange(gerado, 33, gerado.length));
        byte[] limpo = MetadadosUtil.remover(comTexto, "image/png");

        assertFalse(contem(limpo, "Location"));
        BufferedImage lida = ImageIO.read(new ByteArrayInputStream(limpo));
        assertNotNull(lida);
        assertEquals(5, lida.getWidth());
        assertEquals(0xFF00FF00, lida.getRGB(2, 2));
    }

    @Test
    @DisplayName("outros formatos passam sem alteracao")
    void outrosFormatos() {
        byte[] pdf = ascii("%PDF-1.7 /Author (Fulano)");
        assertSame(pdf, MetadadosUtil.remover(pdf, "application/pdf"));
        assertNull(MetadadosUtil.remover(null, "image/png"));
    }
}
