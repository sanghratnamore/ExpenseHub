package com.expensehub.backend.controller;

import com.expensehub.backend.dto.HealthResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {

    @GetMapping("/api/health")
    public HealthResponse health() {
        return new HealthResponse(
                "UP",
                "ExpenseHub backend is running"
        );
    }
}