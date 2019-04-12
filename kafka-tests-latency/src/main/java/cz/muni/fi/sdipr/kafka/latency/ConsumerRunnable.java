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
        this.stopConsumer  = stopConsumer;
        this.repeats = repeats;
        this.mappings = mappings;

        properties.addProperty(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getCanonicalName());
        properties.addProperty(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, ByteArrayDeserializer.class.getCanonicalName());
        properties.logProperties("consumer");

        this.properties = properties;
    }

    @Override
    public void run() {
        int messagesInTransaction = mappings.stream().mapToInt(TopicMapping::getMessages).sum();
        int totalMessages = repeats * messagesInTransaction;
        logger.info("Total messages: {} x {} = {}", repeats, messagesInTransaction, totalMessages);
        NetworkStats stats = new NetworkStats(repeats * messagesInTransaction);

        DatumReader<Payload> reader = new SpecificDatumReader<>(Payload.class);
        BinaryDecoder decoder = null;
        Payload payload = null;

        KafkaConsumer<String, byte[]> kafkaConsumer = new KafkaConsumer<>(properties.getProperties());

        try {
            List<String> topics = mappings.stream().map(TopicMapping::getTopicName).collect(Collectors.toList());

            kafkaConsumer.subscribe(topics);

            kafkaConsumer.seekToEnd(Collections.emptyList());
            kafkaConsumer.poll(Duration.ofMillis(100));

            logger.info("Starting producer ...");
            startProducer.countDown();

            int countDownMessages = totalMessages;
            stats.setStartTime();
            while (countDownMessages > 0 && !stopConsumer.get()) {
                ConsumerRecords<String, byte[]> records = kafkaConsumer.poll(Duration.ofMillis(100));
                for (ConsumerRecord<String, byte[]> record : records) {
                    decoder = DecoderFactory.get().binaryDecoder(record.value(), decoder);
                    payload = reader.read(payload, decoder);

                    stats.recordLatency(System.currentTimeMillis() - payload.getProducerTime());
                    countDownMessages--;
                }
            }
            stats.setStopTime();
        } catch (IOException exp) {
            logger.error(exp.getMessage());
        } finally {
            kafkaConsumer.close();
            logger.info("Consumer shut down ...");
            logger.info("---Consumer results---");
            stats.printLatencyResults();
        }
    }
}
