package cz.muni.fi.sdipr.exceptions;

/**
 * Exception when
 * @author Milos Silhar
 */
public class ParseMappingException extends RuntimeException {

    public ParseMappingException() {
    }

    public ParseMappingException(String message) {
        super(message);
    }

    public ParseMappingException(String message, Throwable cause) {
        super(message, cause);
    }

    public ParseMappingException(Throwable cause) {
        super(cause);
    }

    public ParseMappingException(String message, Throwable cause, boolean enableSuppression, boolean writableStackTrace) {
        super(message, cause, enableSuppression, writableStackTrace);
    }
}
