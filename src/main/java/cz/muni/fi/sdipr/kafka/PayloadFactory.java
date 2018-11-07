package cz.muni.fi.sdipr.kafka;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.nio.charset.StandardCharsets;
import java.util.Random;

/**
 * Class to create payload with specific byte size.
 * @author Milos Silhar
 */
public class PayloadFactory {

    private Logger logger = LoggerFactory.getLogger(PayloadFactory.class);

    private int byteSize;

    public PayloadFactory(int byteSize) {
        this.byteSize = byteSize;
    }

    /**
     * Creates byte array of specific size.
     * @return
     */
    public byte[] getPayload() {
        byte[] payload = new byte[byteSize];
        byte[] alphabet = "abcdefghijklmnopqrstuvwxyz".getBytes(StandardCharsets.UTF_8);
        Random random = new Random(System.nanoTime());
        int nextIndex;
        for (int i = 0; i < byteSize; i++) {
            nextIndex = random.nextInt(alphabet.length);
            payload[i] = alphabet[nextIndex];
        }
        logger.trace("Payload created with size {} B", payload.length);
        return payload;
    }
}
