package com.rtd.dashboard.service;

import com.rtd.dashboard.entity.Service;
import com.rtd.dashboard.repository.ServiceRepository;

import java.util.List;

@org.springframework.stereotype.Service
public class ServiceService {

    private final ServiceRepository serviceRepository;

    public ServiceService(ServiceRepository serviceRepository) {
        this.serviceRepository = serviceRepository;
    }

    public List<Service> findAll() {
        return serviceRepository.findAll();
    }
}
