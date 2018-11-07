package cz.muni.fi.sdipr.kafka;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;

/**
 *
 * @author Milos Silhar
 */
public class NetworkStats {

    private Logger logger = LoggerFactory.getLogger(NetworkStats.class);

    private static final double NANOSECOND_TO_SECOND = 1.0e9;
    private static final double NANOSECOND_TO_MILISECOND = 1.0e6;
    private static final double BYTES_TO_MEGABYTES = 1024.0 * 1024.0;

    private long        startTime;
    private long        messagesSent;
    private long        bytesSent;
    private long        totalMessages;
    private List<Long>  latencies;

    /**
     *
     * @param numberOfRecords
     */
    public NetworkStats(long numberOfRecords) {
        this.startTime     = System.nanoTime();
        this.messagesSent  = 0;
        this.bytesSent     = 0;
        this.totalMessages = numberOfRecords;
        this.latencies     = new ArrayList<>((int) numberOfRecords);
    }

    /**
     *
     * @param latency
     * @param bytes
     */
    public void recordMessage(long latency, long bytes) {
        latencies.add(latency);
        bytesSent += bytes;
        messagesSent++;
        if (messagesSent % (totalMessages / 10) == 0) {
            printPartialResults();
        }
    }

    /**
     * Prints or rather logs (info level) results to configured output in logback.xml.
     */
    public void printResults() {
        long elapsed = System.nanoTime() - startTime;
        double elapsedSeconds = elapsed / NANOSECOND_TO_SECOND;

        // network speed calculations
        double messagesPerSec  = messagesSent / elapsedSeconds;
        double bytesPerSec = bytesSent / elapsedSeconds;

        // latencies statistics
        double averageLatency = latencies.stream()
                .mapToDouble((latency) -> latency / NANOSECOND_TO_MILISECOND)
                .average().getAsDouble();
        double minLatency = latencies.stream()
                .mapToDouble((latency) -> latency / NANOSECOND_TO_MILISECOND)
                .min().getAsDouble();
        double maxLatency = latencies.stream()
                .mapToDouble((latency) -> latency / NANOSECOND_TO_MILISECOND)
                .max().getAsDouble();
        logger.info("Final results (total time: {}s)", elapsedSeconds);
        logger.info("{} messages sent, {} MB sent", messagesSent, bytesSent / BYTES_TO_MEGABYTES);
        logger.info("{} msg/s, bytes per sec: {} MB/s", messagesPerSec, bytesPerSec / BYTES_TO_MEGABYTES);
        logger.info("{} ms average latency, {} ms minimum latency, {} ms maximum latency", averageLatency, minLatency, maxLatency);
    }

    /**
     * Prints or rather logs (info level) partial results every 10% messages.
     */
    public void printPartialResults() {
        long elapsed = System.nanoTime() - startTime;
        double elapsedSeconds = elapsed / NANOSECOND_TO_SECOND;

        // network speed calculations
        double messagesPerSec  = messagesSent / elapsedSeconds;
        double bytesPerSec = bytesSent / elapsedSeconds;

        logger.info("Messages sent {} (elapsed time: {}s) speed: {} msg/s {} MB/s",
                messagesSent, elapsedSeconds, messagesPerSec, bytesPerSec / BYTES_TO_MEGABYTES);
    }
}
