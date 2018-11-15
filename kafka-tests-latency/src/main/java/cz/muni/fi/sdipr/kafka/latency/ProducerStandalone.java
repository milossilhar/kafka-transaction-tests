package cz.muni.fi.sdipr.kafka.latency;

import cz.muni.fi.sdipr.kafka.common.NetworkStats;
import cz.muni.fi.sdipr.kafka.common.ProducerCallback;
import cz.muni.fi.sdipr.kafka.common.PropertiesLoader;
import cz.muni.fi.sdipr.kafka.common.TopicMapping;
import cz.muni.fi.sdipr.kafka.latency.avro.Payload;
import org.apache.avro.io.DatumWriter;
import org.apache.avro.io.Encoder;
import org.apache.avro.io.EncoderFactory;
import org.apache.avro.specific.SpecificDatumWriter;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.ByteArraySerializer;
import org.apache.kafka.common.serialization.StringSerializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.ByteArrayOutputStream;
import java.io.IOException;

/**
 * @author Milos Silhar
 */
public class ProducerStandalone {

    private static Logger logger = LoggerFactory.getLogger(ProducerStandalone.class);

    private boolean             isTransactional;
    private int                 repeats;
    private PropertiesLoader    properties;
    private TopicMapping  mapping;

    public ProducerStandalone(PropertiesLoader properties, int repeats, TopicMapping mapping) {
        this.repeats    = repeats;
        this.mapping    = mapping;
        this.isTransactional = properties.hasProperty(ProducerConfig.TRANSACTIONAL_ID_CONFIG);

        properties.addProperty(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getCanonicalName());
        properties.addProperty(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, ByteArraySerializer.class.getCanonicalName());

        logger.info("Creating ProducerStandalone with properties ...");
        properties.logProperties();
        this.properties = properties;
    }

    /**
     * Creates {@link ProducerRunnable} object in new thread and waits for user to hit Enter to start this producer.
     */
    public void produce() {
        KafkaProducer<String, byte[]> kafkaProducer = new KafkaProducer<>(properties.getProperties());
        NetworkStats stats = new NetworkStats(repeats * mapping.getMessages());
        try {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            DatumWriter<Payload> writer = new SpecificDatumWriter<>(Payload.class);
            Encoder encoder = EncoderFactory.get().directBinaryEncoder(out, null);
            Payload payload;

            if (isTransactional) kafkaProducer.initTransactions();

            stats.setStartTime();
            for (int i = 0; i < repeats; i++) {
                if (isTransactional) { kafkaProducer.beginTransaction(); }

                for (int j = 0; j < mapping.getMessages(); j++) {
                    payload = new Payload();
                    payload.setProducerTime(System.nanoTime());
                    payload.setPayload(mapping.getStringPayload());

                    writer.write(payload, encoder);
                    encoder.flush();

                    kafkaProducer.send(new ProducerRecord<>(mapping.getTopicName(), out.toByteArray()),
                            new ProducerCallback(stats, mapping.getByteSize()));
                    out.reset();
                }

                if (isTransactional) { kafkaProducer.commitTransaction(); }
            }
        } catch (IOException exp) {
            logger.error(exp.getMessage());
        } finally {
            kafkaProducer.close();
            stats.printResults();
        }
    }
}
