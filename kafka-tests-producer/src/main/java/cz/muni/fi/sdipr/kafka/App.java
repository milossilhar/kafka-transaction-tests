package cz.muni.fi.sdipr.kafka;

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

/**
 * Main class that runs Kafka Producer tests with transactional API.
 * @author Milos Silhar
 */
public class App 
{
    private static Logger logger = LoggerFactory.getLogger(App.class);

    private static final String DEFAULT_PRODUCER_PROP_FILE = "producer.properties";
    private static final int DEFAULT_REPEATS = 1;

    public static void main( String[] args )  {

        Options options = createArguments();

        try {
            CommandLineParser parser = new DefaultParser();
            CommandLine line = parser.parse(options, args, false);

            File propFile = line.hasOption("producer-props") ?
                    PatternOptionBuilder.FILE_VALUE.cast(line.getParsedOptionValue("producer-props")) :
                    new File(DEFAULT_PRODUCER_PROP_FILE);
            Number repeatsNumber = line.hasOption("repeats") ?
                    PatternOptionBuilder.NUMBER_VALUE.cast(line.getParsedOptionValue("repeats")) :
                    new Integer(DEFAULT_REPEATS);
            int repeats = repeatsNumber.intValue();
            String[] topicMapping = line.getOptionValues("topic-mapping");

            List<TopicMapping> mappings = TopicMappings.parse(topicMapping);

            logger.info("Number of repeats is {} time(s)", repeats);

            PropertiesLoader propertiesLoader = new PropertiesLoader(propFile);
            ProducerPerformance producerPerformance = new ProducerPerformance(propertiesLoader, mappings);

            if (line.hasOption("pause")) {
                logger.info("Press ENTER to start test ...");
                System.in.read();
            }

            logger.info("Executing producer test ...");
            producerPerformance.produce(repeats);
            producerPerformance.close();
        } catch (ParseException | ParseMappingException exp) {
            logger.error(exp.getMessage());
            printHelp(options);
        } catch (IOException exp) {
            logger.error(exp.getMessage());
        }
    }

    private static Options createArguments() {
        Options options = new Options();

        Option props = Option.builder("p")
                .longOpt("producer-props")
                .required(false)
                .hasArg()
                .argName("file")
                .type(PatternOptionBuilder.FILE_VALUE)
                .desc("path to producer props file\n[default: ./producer.properties]")
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
                .optionalArg(true)
                .desc("pauses after warming kafka producer and waits for input")
                .build();

        options.addOption(props);
        options.addOption(repeats);
        options.addOption(topicMapping);
        options.addOption(pause);

        return options;
    }

    private static void printHelp(Options options) {
        HelpFormatter formatter = new HelpFormatter();
        formatter.printHelp("mvn exec:java -Dexec.args=\"ARGS\"", options);
    }
}
