package cz.muni.fi.sdipr.kafka.latency;

import cz.muni.fi.sdipr.kafka.common.PropertiesLoader;
import cz.muni.fi.sdipr.kafka.common.TopicMapping;
import cz.muni.fi.sdipr.kafka.latency.avro.Payload;
import org.apache.avro.io.DatumWriter;
import org.apache.avro.io.Encoder;
import org.apache.avro.io.EncoderFactory;
import org.apache.avro.specific.SpecificDatumWriter;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 *
 * @author Milos Silhar
 */
public class ProducerRunnable implements Runnable {

    private static Logger logger = LoggerFactory.getLogger(ProducerRunnable.class);

    public static final String WARMUP_STRING = "warmupdata";

    private int repeats;

    private PropertiesLoader    properties;
    private List<TopicMapping>  mappings;
    private AtomicBoolean       isTransactional;
    private CountDownLatch      startProducer;
    private AtomicBoolean       stopConsumer;

    public ProducerRunnable(CountDownLatch startProducer, AtomicBoolean stopConsumer, int repeats,
                            PropertiesLoader properties, List<TopicMapping> mappings) {
        this.startProducer = startProducer;
        this.stopConsumer = stopConsumer;
        this.repeats = repeats;
        this.mappings = mappings;
        this.isTransactional = new AtomicBoolean(properties.hasProperty("transactional.id"));

        properties.addProperty("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        properties.addProperty("value.serializer", "org.apache.kafka.common.serialization.ByteArraySerializer");

        logger.info("Creating ProducerRunnable with properties ...");
        properties.logProperties();
        this.properties = properties;
    }

    @Override
    public void run() {
        try {
            logger.info("Waiting for consumer to startup ...");
            startProducer.await();

            logger.info("Sleeping for 0.5s ...");
            Thread.sleep(500);
            logger.info("Starting producer ...");
            Producer<String, byte[]> kafkaProducer = new KafkaProducer<>(properties.getProperties());

            try {

                if (isTransactional.get()) kafkaProducer.initTransactions();

                ByteArrayOutputStream out = new ByteArrayOutputStream();
                DatumWriter<Payload> writer = new SpecificDatumWriter<>(Payload.class);
                Encoder encoder = EncoderFactory.get().directBinaryEncoder(out, null);

                for (int i = 0; i < repeats; i++) {
                    if (isTransactional.get()) {
                        kafkaProducer.beginTransaction();
                    }

                    for (TopicMapping mapping : mappings) {
                        for (int j = 0; j < mapping.getMessages(); j++) {
                            Payload payload = new Payload();
                            payload.setProducerTime(System.nanoTime());
                            payload.setPayload(mapping.getStringPayload());

                            writer.write(payload, encoder);
                            encoder.flush();

                            kafkaProducer.send(new ProducerRecord<>(mapping.getTopicName(), null, out.toByteArray()));
                            out.reset();
                        }
                    }

                    if (isTransactional.get()) {
                        kafkaProducer.commitTransaction();
                    }
                }
            } catch (IOException exp) {
                logger.error(exp.getMessage());
            } finally {
                kafkaProducer.close();
                logger.info("Sent all messages ...");
                Thread.sleep(1000);
                logger.info("Shutting down consumer ...");
                stopConsumer.set(true);
            }
        } catch (InterruptedException exp) {
            logger.error(exp.getMessage());
        }
    }
}
