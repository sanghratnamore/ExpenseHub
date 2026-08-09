package com.expensehub.backend.dto;

public class HealthResponse {

    private String status;
    private String message;

    public HealthResponse(String status, String message) {
        this.status = status;
        this.message = message;
    }

    public String getStatus() {
        return status;
    }

    public String getMessage() {
        return message;
    }
}