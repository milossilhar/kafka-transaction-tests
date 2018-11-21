package cz.muni.fi.sdipr.kafka.latency;

import cz.muni.fi.sdipr.kafka.common.NetworkStats;
import cz.muni.fi.sdipr.kafka.common.ProducerCallback;
import cz.muni.fi.sdipr.kafka.common.PropertiesLoader;
import cz.muni.fi.sdipr.kafka.common.TopicMapping;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

/**
 * @author Milos Silhar
 */
public class ProducerTest {

    private Logger logger = LoggerFactory.getLogger(ProducerTest.class);

    private static final String WARMUP_STRING = "warmupdata";

    private Producer<String, byte[]> kafkaProducer;
    private boolean isTransactional;
    private List<TopicMapping> mappings;
    private NetworkStats stats;

    public ProducerTest(PropertiesLoader properties, List<TopicMapping> mappings) {
        this.mappings = mappings;
        this.isTransactional = properties.hasProperty("transactional.id");

        properties.addProperty(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer");
        properties.addProperty(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.ByteArraySerializer");
        properties.logProperties("producer");

        kafkaProducer = new KafkaProducer<>(properties.getProperties());

        logger.info("Warming up Kafka producer ...");
        if (isTransactional) {
            kafkaProducer.initTransactions();
            kafkaProducer.beginTransaction();
        }
        for (TopicMapping mapping : mappings) {
            byte[] data = WARMUP_STRING.getBytes();
            kafkaProducer.send(new ProducerRecord<>(mapping.getTopicName(), null, data));
        }
        if (isTransactional) {
            kafkaProducer.commitTransaction();
        }
    }

    /**
     * Producer sends n times given mapping to Kafka. After every loop of mappings is transaction committed if transactional.id is specified.
     * @param times
     */
    public void produce(int times) {
        int messagesInTransaction = mappings.stream()
                .mapToInt((m) -> m.getMessages())
                .sum();
        stats = new NetworkStats(times * messagesInTransaction);

        for (int i = 0; i < times; i++) {
            if (isTransactional) { kafkaProducer.beginTransaction(); }

            for(TopicMapping mapping : mappings) {
                for(int j = 0; j < mapping.getMessages(); j++) {
                    kafkaProducer.send(
                            new ProducerRecord<>(mapping.getTopicName(), null, mapping.getPayload()),
                            new ProducerCallback(stats, mapping.getByteSize()));
                }
            }

            if (isTransactional) { kafkaProducer.commitTransaction(); }
        }
    }

    /**
     * Closes Kafka instance in this class and prints results.
     */
    public void close() {
        kafkaProducer.close();
        stats.printResults();
    }
}
