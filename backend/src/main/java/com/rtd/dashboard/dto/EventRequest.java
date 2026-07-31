package com.rtd.dashboard.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;

public class EventRequest {

    @NotBlank
    @Size(max = 100)
    private String serviceName;

    @NotBlank
    @Size(max = 50)
    private String eventType;

    @NotBlank
    @Pattern(regexp = "INFO|WARNING|ERROR", message = "must be INFO, WARNING, or ERROR")
    private String severity;

    @NotBlank
    @Size(max = 500)
    private String message;

    @NotNull
    private LocalDateTime timestamp;

    public String getServiceName() {
        return serviceName;
    }

    public void setServiceName(String serviceName) {
        this.serviceName = serviceName;
    }

    public String getEventType() {
        return eventType;
    }

    public void setEventType(String eventType) {
        this.eventType = eventType;
    }

    public String getSeverity() {
        return severity;
    }

    public void setSeverity(String severity) {
        this.severity = severity;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public LocalDateTime getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(LocalDateTime timestamp) {
        this.timestamp = timestamp;
    }
}
