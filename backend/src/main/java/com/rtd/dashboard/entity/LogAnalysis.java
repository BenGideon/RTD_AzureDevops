package com.rtd.dashboard.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

@Entity
@Table(name = "LogAnalysis")
public class LogAnalysis {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "file_name", nullable = false, length = 260)
    private String fileName;

    @Column(name = "processed_time", nullable = false)
    private LocalDateTime processedTime;

    @Column(name = "records_processed", nullable = false)
    private Integer recordsProcessed;

    @Column(name = "errors_found", nullable = false)
    private Integer errorsFound;

    public Integer getId() {
        return id;
    }

    public String getFileName() {
        return fileName;
    }

    public void setFileName(String fileName) {
        this.fileName = fileName;
    }

    public LocalDateTime getProcessedTime() {
        return processedTime;
    }

    public void setProcessedTime(LocalDateTime processedTime) {
        this.processedTime = processedTime;
    }

    public Integer getRecordsProcessed() {
        return recordsProcessed;
    }

    public void setRecordsProcessed(Integer recordsProcessed) {
        this.recordsProcessed = recordsProcessed;
    }

    public Integer getErrorsFound() {
        return errorsFound;
    }

    public void setErrorsFound(Integer errorsFound) {
        this.errorsFound = errorsFound;
    }
}
