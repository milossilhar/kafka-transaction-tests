package cz.muni.fi.sdipr.kafka.latency;

import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.PatternOptionBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 *
 * @author Milos Silhar
 */
public class App {

    private static Logger logger = LoggerFactory.getLogger(App.class);
    private static AtomicBoolean startProducer = new AtomicBoolean(false);
    private static AtomicBoolean stopConsumer = new AtomicBoolean(false);

    public static void main(String[] args) throws IOException {
        ExecutorService executorService = Executors.newFixedThreadPool(2);

        executorService.execute(new ConsumerRunnable(startProducer, stopConsumer));
        executorService.execute(new ProducerRunnable(startProducer));

        logger.info("Waiting for signal to stop consumer ...");
        System.in.read();
        stopConsumer.set(true);

        executorService.shutdown();
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

        Option avro = Option.builder("a")
                .longOpt("use-avro")
                .required(false)
                .hasArg(false)
                .desc("For test uses Apache Avro message schema")
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

        Option pause = Option.builder("s")
                .longOpt("pause")
                .hasArg(false)
                .desc("pauses after warming kafka producer and waits for input")
                .build();

        options.addOption(propsProducer);
        options.addOption(propsConsumer);
        options.addOption(repeats);
        options.addOption(topicMapping);
        options.addOption(avro);
        options.addOption(pause);

        return options;
    }

    private static void printHelp(Options options) {
        HelpFormatter formatter = new HelpFormatter();
        formatter.printHelp("mvn exec:java -Dexec.args=\"ARGS\"", options);
    }
}
