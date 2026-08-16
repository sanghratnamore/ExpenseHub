package com.expensehub.backend.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public class GroupResponse {

    private UUID id;
    private String name;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    private UUID createdById;
    private String createdByName;
    private String createdByEmail;

    public GroupResponse(
            UUID id,
            String name,
            LocalDateTime createdAt,
            LocalDateTime updatedAt,
            UUID createdById,
            String createdByName,
            String createdByEmail
    ) {
        this.id = id;
        this.name = name;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
        this.createdById = createdById;
        this.createdByName = createdByName;
        this.createdByEmail = createdByEmail;
    }

    public UUID getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public UUID getCreatedById() {
        return createdById;
    }

    public String getCreatedByName() {
        return createdByName;
    }

    public String getCreatedByEmail() {
        return createdByEmail;
    }
}