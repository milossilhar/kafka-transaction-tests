package cz.muni.fi.sdipr.kafka;

import org.apache.kafka.clients.producer.Callback;
import org.apache.kafka.clients.producer.RecordMetadata;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Class that implements {@link Callback} interface and is called on every acknowledged sent message from Kafka.
 * @author Milos Silhar
 */
public class PerformanceCallback implements Callback {

    private Logger logger = LoggerFactory.getLogger(PerformanceCallback.class);

    private NetworkStats networkStats;
    private long bytesSent;

    private long startTime;

    /**
     * Constructs PerformanceCallback object with given parameters.
     * @param stats {@link NetworkStats} object to which record sent message.
     * @param bytesSent Number of bytes sent in message.
     */
    public PerformanceCallback(NetworkStats stats, long bytesSent) {
        this.networkStats = stats;
        this.bytesSent = bytesSent;

        this.startTime = System.nanoTime();
    }

    @Override
    public void onCompletion(RecordMetadata recordMetadata, Exception exception) {
        long endTime = System.nanoTime();
        long latency = endTime - startTime;
        logger.trace("Recorded message of size {}B with latency {}ns", bytesSent, latency);
        networkStats.recordMessage(latency, bytesSent);
        if (exception != null) {
            logger.error(exception.getMessage());
        }
    }
}
