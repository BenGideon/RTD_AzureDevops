package com.rtd.dashboard.service;

import com.rtd.dashboard.entity.Service;
import com.rtd.dashboard.repository.ServiceRepository;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class ServiceServiceTest {

    @Test
    void findAllReturnsRepositoryData() {
        ServiceRepository repository = mock(ServiceRepository.class);
        Service service = new Service();
        service.setServiceName("spring-api");

        when(repository.findAll()).thenReturn(List.of(service));

        ServiceService serviceService = new ServiceService(repository);

        assertThat(serviceService.findAll()).containsExactly(service);
    }
}
