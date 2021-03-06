package cz.muni.fi.sdipr.kafka.common;

import cz.muni.fi.sdipr.kafka.common.TopicMapping;
import cz.muni.fi.sdipr.kafka.common.exceptions.ParseMappingException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;

/**
 * Class to parse topic mappings and creates new {@link List} of {@link TopicMapping} obejcts.
 * @author Milos Silhar
 */
public class TopicMappings {

    private Logger logger = LoggerFactory.getLogger(TopicMapping.class);

    /**
     * Parses raw topic mapping and creates {@link TopicMapping} objects.
     * @param rawTopicMapping Parsed topic mappings from command line.
     */
    public static List<TopicMapping> parse(String[] rawTopicMapping) {
        if (rawTopicMapping == null) {
            throw new IllegalArgumentException("rawTopicMapping is null");
        }
        if (rawTopicMapping.length % 3 != 0) {
            throw new ParseMappingException("rawTopicMapping should be in format name[string],count[int],size[int]");
        }

        List<TopicMapping> mappings = new ArrayList<>();
        int length = rawTopicMapping.length / 3;
        for (int i = 0; i < length; i++) {
            int index = i * 3;
            String name         = rawTopicMapping[index];
            String messages     = rawTopicMapping[index + 1];
            String size         = rawTopicMapping[index + 2];

            try {
                int numberMessages  = Integer.parseInt(messages);
                int sizeBytes      = Integer.parseInt(size);
                mappings.add(new TopicMapping(name, numberMessages, sizeBytes));
            } catch (NumberFormatException exp) {
                throw new ParseMappingException(exp.getMessage(), exp);
            }
        }

        return mappings;
    }

    /**
     * Parses raw one topic mapping and creates {@link TopicMapping} object.
     * @param rawTopicMapping Parsed topic mapping from command line.
     */
    public static TopicMapping parseMapping(String[] rawTopicMapping) {
        if (rawTopicMapping == null) {
            throw new IllegalArgumentException("rawTopicMapping is null");
        }
        if (rawTopicMapping.length != 3 && rawTopicMapping.length != 2) {
            throw new ParseMappingException("rawTopicMapping should be in format name[string],{count[int]},size[int]");
        }

        boolean hasCount = rawTopicMapping.length == 3;

        String name     = rawTopicMapping[0];
        String messages = hasCount ? rawTopicMapping[1] : "1";
        String size     = hasCount ? rawTopicMapping[2] : rawTopicMapping[1];

        try {
            int numberMessages = Integer.parseInt(messages);
            int sizeBytes      = Integer.parseInt(size);
            return new TopicMapping(name, numberMessages, sizeBytes);
        } catch (NumberFormatException exp) {
            throw new ParseMappingException(exp.getMessage(), exp);
        }
    }
}
