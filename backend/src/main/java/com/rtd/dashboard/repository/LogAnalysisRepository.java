package com.rtd.dashboard.repository;

import com.rtd.dashboard.entity.LogAnalysis;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LogAnalysisRepository extends JpaRepository<LogAnalysis, Integer> {
}
