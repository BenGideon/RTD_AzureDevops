package com.rtd.dashboard.controller;

import com.rtd.dashboard.dto.EventRequest;
import com.rtd.dashboard.entity.Event;
import com.rtd.dashboard.service.EventService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(EventController.class)
class EventControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private EventService eventService;

    @Test
    void getEventsReturnsData() throws Exception {
        Event event = buildEvent();

        when(eventService.findAll(any())).thenReturn(new PageImpl<>(List.of(event), PageRequest.of(0, 50), 1));

        mockMvc.perform(get("/api/events?page=0&size=50"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content[0].serviceName").value("spring-api"))
                .andExpect(jsonPath("$.content[0].severity").value("INFO"));
    }

    @Test
    void postEventsCreatesEvent() throws Exception {
        when(eventService.create(any(EventRequest.class))).thenReturn(buildEvent());

        mockMvc.perform(post("/api/events")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "serviceName": "spring-api",
                                  "eventType": "HEALTH_CHECK",
                                  "severity": "INFO",
                                  "message": "API health check passed",
                                  "timestamp": "2026-07-31T17:00:00"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.serviceName").value("spring-api"))
                .andExpect(jsonPath("$.eventType").value("HEALTH_CHECK"));
    }

    private Event buildEvent() {
        Event event = new Event();
        event.setServiceName("spring-api");
        event.setEventType("HEALTH_CHECK");
        event.setSeverity("INFO");
        event.setMessage("API health check passed");
        event.setTimestamp(LocalDateTime.of(2026, 7, 31, 17, 0));
        return event;
    }
}
