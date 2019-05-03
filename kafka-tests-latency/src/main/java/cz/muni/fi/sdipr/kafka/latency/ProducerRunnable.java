package cz.muni.fi.sdipr.kafka.latency;

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
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 *
 * @author Milos Silhar
 */
public class ProducerRunnable implements Runnable {

    private static Logger logger = LoggerFactory.getLogger(ProducerRunnable.class);

    private static final int INIT_WAIT     = 5000; // milliseconds
    private static final int FINAL_WAIT    = 2000; // milliseconds before consumer is shut down
    private static final int SEND_WAIT     = 20; // milliseconds to wait after each send

    private int repeats;

    private PropertiesLoader    properties;
    private List<TopicMapping>  mappings;
    private AtomicBoolean       isTransactional;
    private CountDownLatch      startProducer;
    private AtomicBoolean       stopConsumer;

    public ProducerRunnable(CountDownLatch startProducer, AtomicBoolean stopConsumer, int repeats,
                            PropertiesLoader properties, List<TopicMapping> mappings) {
        this.startProducer = startProducer;
        this.stopConsumer  = stopConsumer;
        this.repeats = repeats;
        this.mappings = mappings;
        this.isTransactional = new AtomicBoolean(properties.hasProperty(ProducerConfig.TRANSACTIONAL_ID_CONFIG));

        properties.addProperty(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getCanonicalName());
        properties.addProperty(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, ByteArraySerializer.class.getCanonicalName());
        properties.logProperties("producer");

        this.properties = properties;
    }

    @Override
    public void run() {
        try {
            logger.info("Waiting to start ...");
            startProducer.await();

            Thread.sleep(INIT_WAIT);

            int messages = mappings.stream().mapToInt(TopicMapping::getMessages).sum();
            KafkaProducer<String, byte[]> kafkaProducer = new KafkaProducer<>(properties.getProperties());
            //NetworkStats stats = new NetworkStats(repeats * messages);

            try {
                if (isTransactional.get()) { kafkaProducer.initTransactions(); }

                ByteArrayOutputStream out = new ByteArrayOutputStream();
                DatumWriter<Payload> writer = new SpecificDatumWriter<>(Payload.class);
                Encoder encoder = EncoderFactory.get().directBinaryEncoder(out, null);

                logger.info("Producing ...");
                //stats.setStartTime();
                for (int i = 0; i < repeats; i++) {
                    if (isTransactional.get()) { kafkaProducer.beginTransaction(); }

                    for (TopicMapping mapping : mappings) {
                        for (int j = 0; j < mapping.getMessages(); j++) {
                            Payload payload = new Payload();
                            payload.setProducerTime(System.currentTimeMillis());
                            payload.setPayload(mapping.getStringPayload());

                            writer.write(payload, encoder);
                            encoder.flush();

                            //kafkaProducer.send(new ProducerRecord<>(mapping.getTopicName(), out.toByteArray()),
                            //        new ProducerCallback(stats, mapping.getByteSize()));
                            kafkaProducer.send(new ProducerRecord<>(mapping.getTopicName(), out.toByteArray()));
                            out.reset();

                            Thread.sleep(SEND_WAIT);
                        }
                    }

                    if (isTransactional.get()) { kafkaProducer.commitTransaction(); }
                }
            } catch (IOException exp) {
                logger.error(exp.getMessage());
            } finally {
                kafkaProducer.close();
                logger.info("Producer shut down ...");
                //stats.setStopTime();
                Thread.sleep(FINAL_WAIT);
                logger.info("Shutting down consumer ...");
                stopConsumer.set(true);
                //logger.info("---Producer results---");
                //stats.printResults();
            }
        } catch (InterruptedException exp) {
            logger.error(exp.getMessage());
        }
    }
}
