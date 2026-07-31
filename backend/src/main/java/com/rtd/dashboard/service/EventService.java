package com.rtd.dashboard.service;

import com.rtd.dashboard.dto.EventRequest;
import com.rtd.dashboard.entity.Event;
import com.rtd.dashboard.repository.EventRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

@org.springframework.stereotype.Service
public class EventService {

    private final EventRepository eventRepository;

    public EventService(EventRepository eventRepository) {
        this.eventRepository = eventRepository;
    }

    public Page<Event> findAll(Pageable pageable) {
        return eventRepository.findAll(pageable);
    }

    public Event create(EventRequest request) {
        Event event = new Event();
        event.setServiceName(request.getServiceName().trim());
        event.setEventType(request.getEventType().trim());
        event.setSeverity(request.getSeverity().trim());
        event.setMessage(request.getMessage().trim());
        event.setTimestamp(request.getTimestamp());
        return eventRepository.save(event);
    }
}
