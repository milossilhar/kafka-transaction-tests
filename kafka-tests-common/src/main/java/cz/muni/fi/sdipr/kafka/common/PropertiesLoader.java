package cz.muni.fi.sdipr.kafka.common;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;
import java.util.stream.Collectors;

/**
 *
 * @author Milos Silhar
 */
public class PropertiesLoader {

    private Logger logger = LoggerFactory.getLogger(PropertiesLoader.class);

    private Properties properties;

    public PropertiesLoader(String filePath) throws IOException {
        this(new File(filePath));
    }

    public PropertiesLoader(File file) throws IOException {
        if (file == null) {
            logger.error("constructor(null) called");
            throw new IllegalArgumentException("file is null");
        }
        if (!file.exists()) {
            logger.error("file {} does not exists", file.getPath());
            throw new FileNotFoundException("file not found");
        }

        this.properties = new Properties();

        try (InputStream input = new FileInputStream(file)) {
            this.properties.load(input);
        }
    }

    /**
     *
     * @param key
     * @param value
     */
    public void addProperty(String key, String value) {
        properties.setProperty(key, value);
    }

    /**
     *
     * @param key
     * @return
     */
    public boolean hasProperty(String key) {
        return properties.getProperty(key) != null;
    }

    /**
     *
     * @return
     */
    public Properties getProperties() {
        return properties;
    }

    /**
     *
     */
    public void logProperties() {
        logProperties("");
    }

    /**
     *
     * @param objectName
     */
    public void logProperties(String objectName) {
        String propertiesString = properties.stringPropertyNames().stream().sorted()
                .map((name) -> {
                    StringBuilder stringBuilder = new StringBuilder();
                    stringBuilder.append(name);
                    stringBuilder.append("=");
                    stringBuilder.append(properties.getProperty(name));
                    stringBuilder.append(System.lineSeparator());
                    return stringBuilder.toString();
                })
                .collect(Collectors.joining());
        logger.info("Configured " + objectName + " properties ..." + System.lineSeparator() + System.lineSeparator() + propertiesString);
    }
}
