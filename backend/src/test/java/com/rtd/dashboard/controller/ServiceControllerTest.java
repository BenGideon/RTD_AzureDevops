package com.rtd.dashboard.controller;

import com.rtd.dashboard.entity.Service;
import com.rtd.dashboard.service.ServiceService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.List;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ServiceController.class)
class ServiceControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private ServiceService serviceService;

    @Test
    void getServicesReturnsData() throws Exception {
        Service service = new Service();
        service.setServiceName("spring-api");
        service.setCurrentStatus("UP");
        service.setLastUpdated(LocalDateTime.of(2026, 7, 31, 17, 0));

        when(serviceService.findAll()).thenReturn(List.of(service));

        mockMvc.perform(get("/api/services"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].serviceName").value("spring-api"))
                .andExpect(jsonPath("$[0].currentStatus").value("UP"));
    }
}
