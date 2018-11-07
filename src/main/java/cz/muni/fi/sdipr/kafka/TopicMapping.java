package cz.muni.fi.sdipr.kafka;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.text.MessageFormat;
import java.util.Objects;

/**
 *
 * @author Milos Silhar
 */
public class TopicMapping {

    private Logger logger = LoggerFactory.getLogger(TopicMapping.class);

    private String  topicName;
    private int     messages;
    private int    byteSize;
    private byte[] payload;

    public TopicMapping(String topicName, int messages, int byteSize) {
        this.topicName  = topicName;
        this.messages   = messages;
        this.byteSize   = byteSize;

        PayloadFactory payloadFactory = new PayloadFactory(byteSize);
        this.payload = payloadFactory.getPayload();

        logger.info("Created TopicMapping to {} send {} x {} B msg(s)", topicName, messages, byteSize);
    }

    /**
     *
     * @return
     */
    public String getTopicName() {
        return topicName;
    }

    /**
     *
     * @return
     */
    public int getMessages() {
        return messages;
    }

    /**
     *
     * @return
     */
    public long getByteSize() {
        return byteSize;
    }

    /**
     * Returns created random payload of byteSize size.
     * @return Byte array of specific size.
     */
    public byte[] getPayload() {
        return payload;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof TopicMapping)) return false;
        TopicMapping that = (TopicMapping) o;
        return getMessages() == that.getMessages() &&
                getByteSize() == that.getByteSize() &&
                Objects.equals(getTopicName(), that.getTopicName());
    }

    @Override
    public int hashCode() {
        return Objects.hash(getTopicName(), getMessages(), getByteSize());
    }

    @Override
    public String toString() {
        return MessageFormat.format("Sending to {0} .. {1} message(s) of size {2} B",
                getTopicName(), Integer.toString(getMessages()), Long.toString(getByteSize()));
    }
}
