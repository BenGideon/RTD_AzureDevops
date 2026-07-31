package com.rtd.dashboard.controller;

import com.rtd.dashboard.dto.EventRequest;
import com.rtd.dashboard.entity.Event;
import com.rtd.dashboard.service.EventService;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/events")
public class EventController {

    private final EventService eventService;

    public EventController(EventService eventService) {
        this.eventService = eventService;
    }

    @GetMapping
    public Page<Event> getEvents(
            @PageableDefault(size = 50, sort = "timestamp", direction = Sort.Direction.DESC)
            Pageable pageable) {
        return eventService.findAll(pageable);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Event createEvent(@Valid @RequestBody EventRequest request) {
        return eventService.create(request);
    }
}
