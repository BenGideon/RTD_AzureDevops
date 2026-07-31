package com.rtd.dashboard.exception;

import com.rtd.dashboard.dto.ApiError;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.LinkedHashMap;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger LOGGER = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiError> handleValidation(MethodArgumentNotValidException ex) {
        Map<String, String> fieldErrors = new LinkedHashMap<>();
        ex.getBindingResult().getFieldErrors().forEach(error ->
                fieldErrors.put(error.getField(), error.getDefaultMessage()));

        return build(HttpStatus.BAD_REQUEST, "Validation failed", fieldErrors);
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ApiError> handleDataIntegrity(DataIntegrityViolationException ex) {
        LOGGER.warn("Database constraint violation: {}", ex.getMostSpecificCause().getMessage());
        return build(HttpStatus.CONFLICT, "Request conflicts with database constraints", null);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiError> handleUnexpected(Exception ex) {
        LOGGER.error("Unhandled API error", ex);
        return build(HttpStatus.INTERNAL_SERVER_ERROR, "Unexpected server error", null);
    }

    private ResponseEntity<ApiError> build(
            HttpStatus status,
            String message,
            Map<String, String> fieldErrors) {
        ApiError error = new ApiError(status.value(), status.getReasonPhrase(), message, fieldErrors);
        return ResponseEntity.status(status).body(error);
    }
}
