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
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.IOException;
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
    private static AtomicBoolean  stopConsumer  = new AtomicBoolean(false);

    public static void main(String[] args) throws IOException {

        Options options = createArguments();

        try {
            CommandLineParser parser = new DefaultParser();
            CommandLine line = parser.parse(options, args, false);

            File consumerPropsFile = PatternOptionBuilder.FILE_VALUE.cast(line.getParsedOptionValue("consumer-props"));
            File producerPropsFile = PatternOptionBuilder.FILE_VALUE.cast(line.getParsedOptionValue("producer-props"));
            Number repeatsNumber = PatternOptionBuilder.NUMBER_VALUE.cast(line.getParsedOptionValue("repeats"));
            int repeats = repeatsNumber == null ? 1 : repeatsNumber.intValue();
            String[] topicMapping = line.getOptionValues("topic-mapping");

            List<TopicMapping> mappings = TopicMappings.parse(topicMapping);

            logger.info("Number of repeats is {} time(s)", repeats);

            PropertiesLoader consumerProperties = new PropertiesLoader(consumerPropsFile);
            PropertiesLoader producerProperties = new PropertiesLoader(producerPropsFile);

            ConsumerRunnable consumerRunnable = new ConsumerRunnable(startProducer, stopConsumer, repeats, consumerProperties, mappings);
            ProducerRunnable producerRunnable = new ProducerRunnable(startProducer, stopConsumer, repeats, producerProperties, mappings);

            ExecutorService consumerExecutorService = Executors.newFixedThreadPool(1);
            ExecutorService producerExecutorService = Executors.newFixedThreadPool(1);

            consumerExecutorService.execute(consumerRunnable);
            producerExecutorService.execute(producerRunnable);

            producerExecutorService.shutdown();
            consumerExecutorService.shutdown();
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
                .required()
                .hasArg()
                .argName("file")
                .type(PatternOptionBuilder.FILE_VALUE)
                .desc("path to producer props file")
                .build();

        Option propsConsumer = Option.builder("c")
                .longOpt("consumer-props")
                .required()
                .hasArg()
                .argName("file")
                .type(PatternOptionBuilder.FILE_VALUE)
                .desc("path to producer props file")
                .build();

        Option repeats = Option.builder("n")
                .longOpt("repeats")
                .required(false)
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

        options.addOption(propsProducer);
        options.addOption(propsConsumer);
        options.addOption(repeats);
        options.addOption(topicMapping);

        return options;
    }

    private static void printHelp(Options options) {
        HelpFormatter formatter = new HelpFormatter();
        formatter.printHelp("mvn exec:java -Dexec.args=\"ARGS\"", options);
    }
}
