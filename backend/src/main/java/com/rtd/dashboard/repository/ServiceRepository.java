package com.rtd.dashboard.repository;

import com.rtd.dashboard.entity.Service;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ServiceRepository extends JpaRepository<Service, Integer> {
}
