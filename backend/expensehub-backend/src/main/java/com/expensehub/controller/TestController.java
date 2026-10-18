package com.expensehub.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/test")
public class TestController {

    @GetMapping
    public Map<String, String> testApi() {
        return Map.of(
                "message", "ExpenseHub backend is running"
        );
    }
}