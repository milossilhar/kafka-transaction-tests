package cz.muni.fi.sdipr.kafka.latency;

import cz.muni.fi.sdipr.kafka.common.NetworkStats;
import cz.muni.fi.sdipr.kafka.common.PropertiesLoader;
import cz.muni.fi.sdipr.kafka.common.TopicMapping;
import cz.muni.fi.sdipr.kafka.latency.avro.Payload;
import org.apache.avro.io.BinaryDecoder;
import org.apache.avro.io.DatumReader;
import org.apache.avro.io.DecoderFactory;
import org.apache.avro.specific.SpecificDatumReader;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.time.Duration;
import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.stream.Collectors;

/**
 *
 * @author Milos Silhar
 */
public class ConsumerRunnable implements Runnable {

    private static Logger logger = LoggerFactory.getLogger(ConsumerRunnable.class);

    private int repeats;

    private PropertiesLoader    properties;
    private List<TopicMapping>  mappings;
    private CountDownLatch      startProducer;
    private AtomicBoolean       stopConsumer;

    public ConsumerRunnable(CountDownLatch startProducer, AtomicBoolean stopConsumer, int repeats,
                            PropertiesLoader properties, List<TopicMapping> mappings) {
        this.startProducer = startProducer;
        this.stopConsumer = stopConsumer;
        this.repeats = repeats;
        this.mappings = mappings;

        properties.addProperty("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
        properties.addProperty("value.deserializer", "org.apache.kafka.common.serialization.ByteArrayDeserializer");

        logger.info("Creating ConsumerRunnable with properties ...");
        properties.logProperties();
        this.properties = properties;
    }

    @Override
    public void run() {
        int messagesInTransaction = mappings.stream().mapToInt(TopicMapping::getMessages).sum();
        NetworkStats stats = new NetworkStats(repeats * messagesInTransaction);

        DatumReader<Payload> reader = new SpecificDatumReader<>(Payload.class);
        BinaryDecoder decoder = null;
        Payload payload = null;

        logger.info("Creating KafkaConsumer object ...");
        KafkaConsumer<String, byte[]> kafkaConsumer = new KafkaConsumer<>(properties.getProperties());

        try {
            List<String> topics = mappings.stream().map(TopicMapping::getTopicName).collect(Collectors.toList());
            kafkaConsumer.subscribe(topics);
            logger.info("Starting producer ...");
            startProducer.countDown();

            while (!stopConsumer.get()) {
                ConsumerRecords<String, byte[]> records = kafkaConsumer.poll(Duration.ofMillis(100));
                for (ConsumerRecord<String, byte[]> record : records) {
                    decoder = DecoderFactory.get().binaryDecoder(record.value(), decoder);
                    payload = reader.read(payload, decoder);

                    stats.recordMessage(System.nanoTime() - payload.getProducerTime(), 1);
                }
            }
        } catch (IOException exp) {
            logger.error(exp.getMessage());
        } finally {
            logger.info("Shutting down ...");
            kafkaConsumer.close();
            stats.printResults();
        }
    }
}
