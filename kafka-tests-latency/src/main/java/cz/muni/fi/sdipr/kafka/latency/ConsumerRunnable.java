package cz.muni.fi.sdipr.kafka.latency;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.atomic.AtomicBoolean;

/**
 *
 * @author Milos Silhar
 */
public class ConsumerRunnable implements Runnable {

    private static Logger logger = LoggerFactory.getLogger(ConsumerRunnable.class);
    private AtomicBoolean startProducer;
    private AtomicBoolean stopConsumer;

    public ConsumerRunnable(AtomicBoolean startProducer, AtomicBoolean stopConsumer) {
        this.startProducer = startProducer;
        this.stopConsumer = stopConsumer;
    }

    @Override
    public void run() {
        logger.info("Consumer ready!");
        startProducer.set(true);
        while (!stopConsumer.get()) {
            logger.info("Computing ...");
            try {
                Thread.sleep(1000);
            } catch (InterruptedException exp) {
                logger.error(exp.getMessage());
            }
        }
        logger.info("Consumer ends!");
    }
}
