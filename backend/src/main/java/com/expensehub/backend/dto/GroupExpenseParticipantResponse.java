package com.expensehub.backend.dto;

import java.math.BigDecimal;
import java.util.UUID;

public class GroupExpenseParticipantResponse {

    private UUID id;
    private UUID userId;
    private String userName;
    private BigDecimal shareAmount;

    public GroupExpenseParticipantResponse(
            UUID id,
            UUID userId,
            String userName,
            BigDecimal shareAmount
    ) {
        this.id = id;
        this.userId = userId;
        this.userName = userName;
        this.shareAmount = shareAmount;
    }

    public UUID getId() {
        return id;
    }

    public UUID getUserId() {
        return userId;
    }

    public String getUserName() {
        return userName;
    }

    public BigDecimal getShareAmount() {
        return shareAmount;
    }
}