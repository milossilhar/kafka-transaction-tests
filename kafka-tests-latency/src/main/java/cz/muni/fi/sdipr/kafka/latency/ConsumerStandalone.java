package cz.muni.fi.sdipr.kafka.latency;

import cz.muni.fi.sdipr.kafka.common.NetworkStats;
import cz.muni.fi.sdipr.kafka.common.PropertiesLoader;
import cz.muni.fi.sdipr.kafka.common.TopicMapping;
import cz.muni.fi.sdipr.kafka.latency.avro.Payload;
import org.apache.avro.io.BinaryDecoder;
import org.apache.avro.io.DatumReader;
import org.apache.avro.io.DecoderFactory;
import org.apache.avro.specific.SpecificDatumReader;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.common.serialization.ByteArrayDeserializer;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.time.Duration;
import java.util.Collections;
import java.util.List;

/**
 * @author Milos Silhar
 */
public class ConsumerStandalone {

    private static Logger logger = LoggerFactory.getLogger(ConsumerStandalone.class);

    private int                 repeats;
    private PropertiesLoader    properties;
    private TopicMapping  mapping;

    public ConsumerStandalone(PropertiesLoader properties, int repeats, TopicMapping mapping) {
        this.repeats    = repeats;
        this.mapping    = mapping;

        properties.addProperty(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getCanonicalName());
        properties.addProperty(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, ByteArrayDeserializer.class.getCanonicalName());

        logger.info("Creating ConsumerStandalone with properties ...");
        properties.logProperties();
        this.properties = properties;
    }

    /**
     * Creates {@link ConsumerRunnable} object in new thread and waits for user to hit Enter to stop this consumer.
     */
    public void consume() {
        /*CountDownLatch startProducer = new CountDownLatch(1);
        AtomicBoolean stopConsumer = new AtomicBoolean(false);

        ConsumerRunnable consumerRunnable =
                new ConsumerRunnable(startProducer, stopConsumer, repeats, properties, mappings);

        Thread consumerThread = new Thread(consumerRunnable, "consumer");
        consumerThread.start();

        try {
            logger.info("Waiting for Enter to stop consumer ...");
            System.in.read();
            stopConsumer.set(true);
        } catch (IOException exp) {
            logger.error(exp.getMessage());
        }*/

        int totalMessages = repeats * mapping.getMessages();
        NetworkStats stats = new NetworkStats(totalMessages);

        DatumReader<Payload> reader = new SpecificDatumReader<>(Payload.class);
        BinaryDecoder decoder = null;
        Payload payload = null;

        logger.info("Creating KafkaConsumer object ...");
        KafkaConsumer<String, byte[]> kafkaConsumer = new KafkaConsumer<>(properties.getProperties());

        try {
            logger.info("Subscribing to topics ...");
            kafkaConsumer.subscribe(Collections.singletonList(mapping.getTopicName()));
            logger.info("Seeking end ...");
            kafkaConsumer.seekToEnd(Collections.emptyList());

            logger.info("Polling first messages ...");
            kafkaConsumer.poll(Duration.ofMillis(100));

            stats.setStartTime();
            while (totalMessages > 0) {
                ConsumerRecords<String, byte[]> records = kafkaConsumer.poll(Duration.ofMillis(100));
                for (ConsumerRecord<String, byte[]> record : records) {
                    decoder = DecoderFactory.get().binaryDecoder(record.value(), decoder);
                    payload = reader.read(payload, decoder);
                    stats.recordLatency(System.nanoTime() - payload.getProducerTime());
                    totalMessages--;
                }
            }
        } catch (IOException exp) {
            logger.error(exp.getMessage());
        } finally {
            logger.info("Shutting down ...");
            kafkaConsumer.close();
            stats.printLatencyResults();
        }
    }
}
