package com.rtd.dashboard.service;

import com.rtd.dashboard.dto.EventRequest;
import com.rtd.dashboard.entity.Event;
import com.rtd.dashboard.repository.EventRepository;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class EventServiceTest {

    @Test
    void createTrimsAndSavesEvent() {
        EventRepository repository = mock(EventRepository.class);
        when(repository.save(any(Event.class))).thenAnswer(invocation -> invocation.getArgument(0));

        EventRequest request = new EventRequest();
        request.setServiceName(" spring-api ");
        request.setEventType(" HEALTH_CHECK ");
        request.setSeverity(" INFO ");
        request.setMessage(" API health check passed ");
        request.setTimestamp(LocalDateTime.of(2026, 7, 31, 17, 0));

        EventService eventService = new EventService(repository);
        Event saved = eventService.create(request);

        assertThat(saved.getServiceName()).isEqualTo("spring-api");
        assertThat(saved.getEventType()).isEqualTo("HEALTH_CHECK");
        assertThat(saved.getSeverity()).isEqualTo("INFO");
        assertThat(saved.getMessage()).isEqualTo("API health check passed");
        verify(repository).save(any(Event.class));
    }
}
