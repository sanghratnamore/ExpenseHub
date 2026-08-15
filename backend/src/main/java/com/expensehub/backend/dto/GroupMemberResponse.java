package com.expensehub.backend.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public class GroupMemberResponse {

    private UUID userId;
    private String userName;
    private String email;
    private LocalDateTime joinedAt;

    public GroupMemberResponse(
            UUID userId,
            String userName,
            String email,
            LocalDateTime joinedAt
    ) {
        this.userId = userId;
        this.userName = userName;
        this.email = email;
        this.joinedAt = joinedAt;
    }

    public UUID getUserId() {
        return userId;
    }

    public String getUserName() {
        return userName;
    }

    public String getEmail() {
        return email;
    }

    public LocalDateTime getJoinedAt() {
        return joinedAt;
    }
}