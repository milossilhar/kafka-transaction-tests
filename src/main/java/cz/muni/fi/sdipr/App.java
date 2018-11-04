package cz.muni.fi.sdipr;

import cz.muni.fi.sdipr.exceptions.ParseMappingException;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.apache.commons.cli.PatternOptionBuilder;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.List;
import java.util.Properties;

/**
 * Main class that runs Kafka Producer tests with transactional API.
 * @author Milos Silhar
 */
public class App 
{
    private static Logger logger = LoggerFactory.getLogger(App.class);

    public static void main( String[] args )  {
        Options options = createArguments();
        try {
            CommandLineParser parser = new DefaultParser();

            CommandLine line = parser.parse(options, args, false);

            File propFile = PatternOptionBuilder.FILE_VALUE.cast(line.getParsedOptionValue("producer-props"));
            Number repeatsNumber = PatternOptionBuilder.NUMBER_VALUE.cast(line.getParsedOptionValue("repeats"));
            int repeats = repeatsNumber.intValue();
            String[] topicMapping = line.getOptionValues("topic-mapping");

            List<TopicMapping> mappings = TopicMappings.parse(topicMapping);

            Properties producerProps = new Properties();
            try (InputStream input = new FileInputStream(propFile)) {
                producerProps.load(input);
            } catch (IOException exp) {
                logger.error(exp.getMessage());
                return;
            }
            producerProps.setProperty("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
            producerProps.setProperty("value.serializer", "org.apache.kafka.common.serialization.ByteArraySerializer");
            boolean isTransactional = producerProps.getProperty("transactional.id") != null;

            Producer<String, byte[]> producer = new KafkaProducer<>(producerProps);

            logger.info("Warming up Kafka producer ...");
            if (isTransactional) {
                producer.initTransactions();
                producer.beginTransaction();
            }
            for (TopicMapping mapping : mappings) {
                byte[] data = "warmupdata".getBytes();
                producer.send(new ProducerRecord<>(mapping.getTopicName(), null, data));
            }
            if (isTransactional) {
                producer.commitTransaction();
            }

            logger.info("Starting producer test ...");
            long numberOfMessages = mappings.stream()
                    .mapToLong((m) -> m.getByteSize())
                    .sum();
            NetworkStats stats = new NetworkStats(repeats * numberOfMessages);
            for(int i = 0; i < repeats; i++) {
                if (isTransactional) {
                    producer.beginTransaction();
                }

                for(TopicMapping mapping : mappings) {
                    for(int j = 0; j < mapping.getMessages(); j++) {
                        producer.send(
                                new ProducerRecord<>(mapping.getTopicName(), null, mapping.getPayload()),
                                new PerformanceCallback(stats, mapping.getByteSize()));
                    }
                }

                if (isTransactional) {
                    producer.commitTransaction();
                }
            }
            producer.close();

            stats.printResults();
        } catch (ParseException | ParseMappingException exp) {
            logger.error(exp.getMessage());
            printHelp(options);
        }
    }

    private static Options createArguments() {
        Options options = new Options();

        Option props = Option.builder("p")
                .longOpt("producer-props")
                .required()
                .hasArg()
                .argName("file")
                .type(PatternOptionBuilder.FILE_VALUE)
                .desc("path to producer props file")
                .build();

        Option repeats = Option.builder("n")
                .longOpt("repeats")
                .required()
                .hasArg()
                .argName("int")
                .type(PatternOptionBuilder.NUMBER_VALUE)
                .desc("repeat given scenario n-times")
                .build();

        Option topicMapping = Option.builder("m")
                .longOpt("topic-mapping")
                .required()
                .hasArgs()
                .numberOfArgs(Option.UNLIMITED_VALUES)
                .argName("string,int,int")
                .valueSeparator(',')
                .desc("mapping messages to topics\n[topic name],[# msgs],[msg size]")
                .build();

        options.addOption(props);
        options.addOption(repeats);
        options.addOption(topicMapping);

        return options;
    }

    private static void printHelp(Options options) {
        HelpFormatter formatter = new HelpFormatter();
        formatter.printHelp("mvn exec:java -Dexec.args=\"ARGS\"", options);
    }
}
