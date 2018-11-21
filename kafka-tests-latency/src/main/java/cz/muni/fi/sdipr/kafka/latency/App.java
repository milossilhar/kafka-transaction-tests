package cz.muni.fi.sdipr.kafka.latency;

import cz.muni.fi.sdipr.kafka.common.PropertiesLoader;
import cz.muni.fi.sdipr.kafka.common.TopicMapping;
import cz.muni.fi.sdipr.kafka.common.TopicMappings;
import cz.muni.fi.sdipr.kafka.common.exceptions.ParseMappingException;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.apache.commons.cli.PatternOptionBuilder;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.common.metrics.stats.Count;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 *
 * @author Milos Silhar
 */
public class App {

    private static Logger         logger        = LoggerFactory.getLogger(App.class);
    private static CountDownLatch startProducer = new CountDownLatch(1);
    private static CountDownLatch printProducer = new CountDownLatch(1);

    private static final String DEFAULT_CONSUMER_PROP_FILE = "consumer.properties";
    private static final String DEFAULT_PRODUCER_PROP_FILE = "producer.properties";
    private static final int DEFAULT_REPEATS = 1;

    public static void main(String[] args) {

        Options options = createArguments();

        if (args.length == 0) {
            printHelp(options);
            System.exit(1);
        }

        try {
            CommandLineParser parser = new DefaultParser();
            CommandLine line = parser.parse(options, args, false);

            if (line.hasOption("topic") == line.hasOption("topic-mapping")) {
                logger.error("Either topic or topic-mapping must be set, but not both.");
                printHelp(options);
                System.exit(1);
            }

            File consumerPropsFile = line.hasOption("consumer-props") ?
                    PatternOptionBuilder.FILE_VALUE.cast(line.getParsedOptionValue("consumer-props")) :
                    new File(DEFAULT_CONSUMER_PROP_FILE);
            File producerPropsFile = line.hasOption("producer-props") ?
                    PatternOptionBuilder.FILE_VALUE.cast(line.getParsedOptionValue("producer-props")) :
                    new File(DEFAULT_PRODUCER_PROP_FILE);
            Number repeatsNumber = line.hasOption("repeats") ?
                    PatternOptionBuilder.NUMBER_VALUE.cast(line.getParsedOptionValue("repeats")) :
                    new Integer(DEFAULT_REPEATS);
            int repeats = repeatsNumber.intValue();

            PropertiesLoader consumerProperties = new PropertiesLoader(consumerPropsFile);
            PropertiesLoader producerProperties = new PropertiesLoader(producerPropsFile);

            if (line.hasOption("servers")) {
                consumerProperties.addProperty(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, line.getOptionValue("servers"));
                producerProperties.addProperty(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, line.getOptionValue("servers"));
            }

            logger.info("Topic mapping in one batch ...");
            List<TopicMapping> mappings = new ArrayList<>();
            if (line.hasOption("topic")) mappings.add(TopicMappings.parseMapping(line.getOptionValues("topic")));
            if (line.hasOption("topic-mapping")) mappings.addAll(TopicMappings.parse(line.getOptionValues("topic-mapping")));


            if (line.hasOption("producer-alone")) {
                ProducerPerformance producerPerformance = new ProducerPerformance(producerProperties, mappings);
                producerPerformance.produce(repeats);
                producerPerformance.close();
            }
            else if (line.hasOption("topic")) {
                ConsumerProducerRunnable consumerProducerRunnable =
                        new ConsumerProducerRunnable(consumerProperties, producerProperties, repeats, mappings.get(0));

                consumerProducerRunnable.run();
            }
            else if (line.hasOption("topic-mapping")) {
                ConsumerRunnable consumerRunnable = new ConsumerRunnable(startProducer, printProducer, repeats, consumerProperties, mappings);
                ProducerRunnable producerRunnable = new ProducerRunnable(startProducer, printProducer, repeats, producerProperties, mappings);

                Thread consumerThread = new Thread(consumerRunnable, "consumer");
                Thread producerThread = new Thread(producerRunnable, "producer");

                consumerThread.start();
                producerThread.start();
            }
        } catch (ParseException | ParseMappingException exp) {
            logger.error(exp.getMessage());
            printHelp(options);
        } catch (IOException exp) {
            logger.error(exp.getMessage());
        }
    }

    private static Options createArguments() {
        Options options = new Options();

        Option propsProducer = Option.builder("p")
                .longOpt("producer-props")
                .required(false)
                .hasArg()
                .argName("file")
                .type(PatternOptionBuilder.FILE_VALUE)
                .desc("path to producer props file" + System.lineSeparator() + "default: " + DEFAULT_PRODUCER_PROP_FILE)
                .build();

        Option propsConsumer = Option.builder("c")
                .longOpt("consumer-props")
                .required(false)
                .hasArg()
                .argName("file")
                .type(PatternOptionBuilder.FILE_VALUE)
                .desc("path to consumer props file" + System.lineSeparator() + "default: " + DEFAULT_CONSUMER_PROP_FILE)
                .build();

        Option producerAlone = Option.builder("P")
                .longOpt("producer-alone")
                .required(false)
                .hasArg(false)
                .desc("runs only producer in standalone mode")
                .build();

        Option repeats = Option.builder("n")
                .longOpt("repeats")
                .required(false)
                .hasArg()
                .argName("int")
                .type(PatternOptionBuilder.NUMBER_VALUE)
                .desc("repeat given scenario n-times" + System.lineSeparator() + "default: " + DEFAULT_REPEATS)
                .build();

        Option topicMapping = Option.builder("m")
                .longOpt("topic-mapping")
                .required(false)
                .hasArgs()
                .numberOfArgs(Option.UNLIMITED_VALUES)
                .argName("string,int,int")
                .valueSeparator(',')
                .desc("mapping messages to topics" + System.lineSeparator() + "topic-name,#-messages,message-size")
                .build();

        Option topic = Option.builder("t")
                .longOpt("topic")
                .required(false)
                .hasArgs()
                .numberOfArgs(Option.UNLIMITED_VALUES)
                .argName("string,{int,}int")
                .valueSeparator(',')
                .desc("to which topic send messages using just one thread" + System.lineSeparator() + "topic-name,[#-messages,]message-size")
                .build();

        Option servers = Option.builder("s")
                .longOpt("servers")
                .required(false)
                .hasArg(true)
                .numberOfArgs(1)
                .argName("hostname1:port1[,hostname2:port2,...]")
                .desc("overrides hostnames for kafka connection from properties files")
                .build();

        options.addOption(propsProducer);
        options.addOption(propsConsumer);
        options.addOption(producerAlone);
        options.addOption(repeats);
        options.addOption(servers);
        options.addOption(topicMapping);
        options.addOption(topic);

        return options;
    }

    private static void printHelp(Options options) {
        HelpFormatter formatter = new HelpFormatter();
        formatter.printHelp("mvn exec:java -Dexec.args=\"ARGS\"", options);
    }
}
