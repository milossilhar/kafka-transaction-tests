package cz.muni.fi.sdipr.kafka.latency;

import cz.muni.fi.sdipr.kafka.common.NetworkStats;
import cz.muni.fi.sdipr.kafka.common.ProducerCallback;
import cz.muni.fi.sdipr.kafka.common.PropertiesLoader;
import cz.muni.fi.sdipr.kafka.common.TopicMapping;
import cz.muni.fi.sdipr.kafka.latency.avro.Payload;
import org.apache.avro.io.BinaryDecoder;
import org.apache.avro.io.DatumReader;
import org.apache.avro.io.DatumWriter;
import org.apache.avro.io.DecoderFactory;
import org.apache.avro.io.Encoder;
import org.apache.avro.io.EncoderFactory;
import org.apache.avro.specific.SpecificDatumReader;
import org.apache.avro.specific.SpecificDatumWriter;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.ByteArrayDeserializer;
import org.apache.kafka.common.serialization.ByteArraySerializer;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.apache.kafka.common.serialization.StringSerializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.Duration;
import java.util.Collections;

/**
 *
 * @author Milos Silhar
 */
public class ConsumerProducerRunnable implements Runnable {

    private static Logger logger = LoggerFactory.getLogger(ConsumerProducerRunnable.class);

    private int repeats;
    private boolean isTransactional;

    private PropertiesLoader consumerProperties;
    private PropertiesLoader producerProperties;
    private TopicMapping mapping;

    public ConsumerProducerRunnable(PropertiesLoader consumerProperties,
                                    PropertiesLoader producerProperties,
                                    int repeats,
                                    TopicMapping mapping) {
        this.repeats = repeats;
        this.mapping = mapping;
        this.isTransactional = producerProperties.hasProperty(ProducerConfig.TRANSACTIONAL_ID_CONFIG);

        consumerProperties.addProperty(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getCanonicalName());
        consumerProperties.addProperty(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, ByteArrayDeserializer.class.getCanonicalName());
        consumerProperties.logProperties("consumer");
        this.consumerProperties = consumerProperties;

        producerProperties.addProperty(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getCanonicalName());
        producerProperties.addProperty(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, ByteArraySerializer.class.getCanonicalName());
        producerProperties.logProperties("producer");
        this.producerProperties = producerProperties;
    }

    @Override
    public void run() {
        logger.info("Total messages: {} x {} = {}", repeats, mapping.getMessages(), repeats * mapping.getMessages());
        NetworkStats consumerStats = new NetworkStats(repeats * mapping.getMessages());
        NetworkStats producerStats = new NetworkStats(repeats * mapping.getMessages());

        KafkaConsumer<String, byte[]> kafkaConsumer = new KafkaConsumer<>(consumerProperties.getProperties());
        KafkaProducer<String, byte[]> kafkaProducer = new KafkaProducer<>(producerProperties.getProperties());

        // avro serialization
        ByteArrayOutputStream out   = new ByteArrayOutputStream();
        DatumWriter<Payload> writer = new SpecificDatumWriter<>(Payload.class);
        Encoder encoder             = EncoderFactory.get().directBinaryEncoder(out, null);
        Payload producedPayload;

        // avro deserialization
        DatumReader<Payload> reader = new SpecificDatumReader<>(Payload.class);
        BinaryDecoder decoder       = null;
        Payload consumedPayload     = null;

        try {
            kafkaConsumer.subscribe(Collections.singletonList(mapping.getTopicName()));

            if (isTransactional) { kafkaProducer.initTransactions(); }

            consumerStats.setStartTime();
            producerStats.setStartTime();
            for (int i = 0; i < repeats; i++) {
                if (isTransactional) { kafkaProducer.beginTransaction(); }

                for (int j = 0; j < mapping.getMessages(); j++) {
                    producedPayload = new Payload();
                    producedPayload.setProducerTime(System.currentTimeMillis());
                    producedPayload.setPayload(mapping.getStringPayload());
                    writer.write(producedPayload, encoder);
                    encoder.flush();

                    kafkaProducer.send(new ProducerRecord<>(mapping.getTopicName(), out.toByteArray()),
                            new ProducerCallback(producerStats, mapping.getByteSize()));
                    out.reset();
                }

                if (isTransactional) { kafkaProducer.commitTransaction(); }
                logger.info("Transaction {} commited ...", i);

                int countDownLatch = mapping.getMessages();
                while (countDownLatch > 0) {
                    ConsumerRecords<String, byte[]> records = kafkaConsumer.poll(Duration.ofMillis(100));
                    for (ConsumerRecord<String, byte[]> record : records) {
                        decoder = DecoderFactory.get().binaryDecoder(record.value(), decoder);
                        consumedPayload = reader.read(consumedPayload, decoder);
                        consumerStats.recordLatency(System.currentTimeMillis() - consumedPayload.getProducerTime());
                        countDownLatch--;
                    }
                }
            }
            consumerStats.setStopTime();
            producerStats.setStopTime();
        } catch (IOException exp) {
            logger.error(exp.getMessage());
        } finally {
            kafkaConsumer.close();
            kafkaProducer.close();
            logger.info("---Consumer results---");
            consumerStats.printLatencyResults();
            logger.info("---Producer results---");
            producerStats.printResults();
        }
    }
}
