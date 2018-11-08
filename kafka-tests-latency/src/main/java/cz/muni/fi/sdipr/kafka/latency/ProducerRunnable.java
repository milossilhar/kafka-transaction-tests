package cz.muni.fi.sdipr.kafka.latency;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.atomic.AtomicBoolean;

/**
 *
 * @author Milos Silhar
 */
public class ProducerRunnable implements Runnable {

    private static Logger logger = LoggerFactory.getLogger(ProducerRunnable.class);
    private AtomicBoolean startProducer;

    public ProducerRunnable(AtomicBoolean startProducer) {
        this.startProducer = startProducer;
    }

    @Override
    public void run() {

    }
}
