package cz.muni.fi.sdipr.kafka.common;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.DoubleSummaryStatistics;
import java.util.List;
import java.util.LongSummaryStatistics;
import java.util.stream.Collectors;
import java.util.stream.DoubleStream;
import java.util.stream.IntStream;

/**
 *
 * @author Milos Silhar
 */
public class NetworkStats {

    private Logger logger = LoggerFactory.getLogger(NetworkStats.class);

    private static DecimalFormat secondFormat           = new DecimalFormat("#.### s");
    private static DecimalFormat millisecondFormat      = new DecimalFormat("#.###### ms");
    private static DecimalFormat bytesFormat            = new DecimalFormat("#.### MB");
    private static DecimalFormat megaBytesPerSecFormat  = new DecimalFormat("#.### MB/s");
    private static DecimalFormat kiloBytesPerSecFormat  = new DecimalFormat("#.### kB/s");
    private static DecimalFormat messagesFormat         = new DecimalFormat("#.# msg/s");

    private static final double SAMPLING_PERCENTAGE = 0.05;

    public static final double MILLISECOND_TO_SECOND         = 1.0e3;
    public static final double BYTES_TO_MEGABYTES           = 1024.0 * 1024.0;
    public static final double BYTES_TO_KILOBYTES           = 1024.0;

    private long        startTime;
    private long        stopTime;
    private long        messagesSent;
    private long        bytesSent;
    private long        totalMessages;
    private long        sampling;
    private List<Long>  latencies;

    /**
     *
     * @param numberOfRecords
     */
    public NetworkStats(int numberOfRecords) {
        this.startTime     = System.currentTimeMillis();
        this.stopTime      = 0;
        this.messagesSent  = 0;
        this.bytesSent     = 0;
        this.totalMessages = numberOfRecords;
        this.latencies     = new ArrayList<>(numberOfRecords);
        this.sampling      = (long) Math.max(totalMessages * SAMPLING_PERCENTAGE, 1.0);
    }

    /**
     * Sets start time to actual system time
     */
    public void setStartTime() {
        this.startTime = System.currentTimeMillis();
    }

    /**
     * Sets stop time to actual system time
     */
    public void setStopTime() { this.stopTime = System.currentTimeMillis(); }

    /**
     * Returns elapsed time in nanoseconds
     */
    public long getElapsedTime() {
        if (stopTime == 0) {
            return System.currentTimeMillis() - startTime;
        }
        return stopTime - startTime;
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
        if (messagesSent % sampling == 0) {
            printPartialResults();
        }
    }

    /**
     *
     * @param latency
     */
    public void recordLatency(long latency) {
        latencies.add(latency);
        messagesSent++;
        if (messagesSent % sampling == 0) {
            printPartialLatencyResults();
        }
    }

    /**
     * Prints or rather logs (info level) results to configured output in logback.xml.
     */
    public void printResults() {
        long elapsedMilli = getElapsedTime();
        double elapsedSeconds = elapsedMilli / MILLISECOND_TO_SECOND;

        // network speed calculations
        double messagesPerSec  = messagesSent / elapsedSeconds;

        logger.info("Final results (total time: {})",
                secondFormat.format(elapsedSeconds));
        logger.info("Size: {} message(s) sent, {} sent",
                messagesSent, bytesFormat.format(bytesSent / BYTES_TO_MEGABYTES));
        logger.info("Speed: {}, bytes per sec: {}",
                messagesFormat.format(messagesPerSec),
                getBytesPerSecond(elapsedSeconds));
        printLatencies();
        printPercentiles(0.25, 0.5, 0.75, 0.95, 0.99);
        printRawLatencies();
    }

    /**
     * Prints or rather logs (info level) partial results when every 10% messages are sent.
     */
    public void printPartialResults() {
        long elapsedMilli = System.currentTimeMillis() - startTime;
        double elapsedSeconds = elapsedMilli / MILLISECOND_TO_SECOND;

        logger.info("Messages sent {} (elapsed time: {}) size: {} [{}]",
                messagesSent, secondFormat.format(elapsedSeconds), bytesFormat.format(bytesSent / BYTES_TO_MEGABYTES),
                getBytesPerSecond(elapsedSeconds));
    }

    /**
     * Prints or rather logs (info level) only latency results to configured output in logback.xml.
     */
    public void printLatencyResults() {
        long elapsedMilli = getElapsedTime();
        double elapsedSeconds = elapsedMilli / MILLISECOND_TO_SECOND;

        logger.info("Final results (total time: {})", secondFormat.format(elapsedSeconds));
        logger.info("Size: {} message(s) received", messagesSent);
        printLatencies();
        printPercentiles(0.25, 0.5, 0.75, 0.95, 0.99);
        printRawLatencies();
    }

    /**
     * Prints or rather logs (info level) partial latency results when every 10% messages are sent.
     */
    public void printPartialLatencyResults() {
        long elapsedMilli = System.currentTimeMillis() - startTime;
        double elapsedSeconds = elapsedMilli / MILLISECOND_TO_SECOND;

        logger.info("Message(s) received {} (elapsed time: {})",
                messagesSent, secondFormat.format(elapsedSeconds));
    }

    /**
     * Prints (logs) all latencies to output.
     */
    public void printRawLatencies() {
        StringBuilder stringBuilder = new StringBuilder();
        stringBuilder.append("RAW Latencies");
        stringBuilder.append(System.lineSeparator()).append(System.lineSeparator());
        for (long lat : latencies) {
            stringBuilder.append("LAT - ").append(lat).append(System.lineSeparator());
        }
        logger.info(stringBuilder.toString());
    }

    private String getBytesPerSecond(double elapsedSeconds) {
        double bytesPerSec = bytesSent / elapsedSeconds;

        if (bytesPerSec / BYTES_TO_MEGABYTES < 1.0) {
            return kiloBytesPerSecFormat.format(bytesPerSec / BYTES_TO_KILOBYTES);
        } else {
            return megaBytesPerSecFormat.format(bytesPerSec / BYTES_TO_MEGABYTES);
        }
    }

    private void printLatencies() {
        LongSummaryStatistics latencyStatistics = latencies.stream().mapToLong(l -> l).summaryStatistics();

        logger.info("Latencies:");
        logger.info("{} average, {} minimum, {} maximum",
                millisecondFormat.format(latencyStatistics.getAverage()),
                millisecondFormat.format(latencyStatistics.getMin()),
                millisecondFormat.format(latencyStatistics.getMax()));
    }

    private void printPercentiles(Double... percentiles) {
        List<Long> values = percentiles(percentiles);
        StringBuilder stringBuilder = new StringBuilder();
        for (int i = 0; i < values.size(); i++) {
            Double percent = percentiles[i] * 100;
            stringBuilder.append(millisecondFormat.format(values.get(i)));
            stringBuilder.append(" ");
            stringBuilder.append(percent.intValue());
            stringBuilder.append("th");
            if (i < values.size() - 1) stringBuilder.append(", ");
        }
        logger.info(stringBuilder.toString());
    }

    private List<Long> percentiles(Double... percentiles) {
        int size = latencies.size();

        List<Integer> indexes = Arrays.stream(percentiles)
                .map(value -> (int) (value * (size - 1)))
                .collect(Collectors.toList());

        List<Long> sortedLatencies  = new ArrayList<>(latencies);
        sortedLatencies.sort(Comparator.naturalOrder());

        return indexes.stream()
                .map(i -> (sortedLatencies.size()) == 0 ? Long.valueOf(0) : sortedLatencies.get(i))
                .collect(Collectors.toList());
    }
}
