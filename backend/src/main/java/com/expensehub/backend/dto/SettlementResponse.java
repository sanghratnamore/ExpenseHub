package com.expensehub.backend.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

public class SettlementResponse {

    private UUID id;
    private UUID groupId;

    private UUID paidById;
    private String paidByName;

    private UUID paidToId;
    private String paidToName;

    private BigDecimal amount;
    private LocalDateTime createdAt;

    public SettlementResponse(
            UUID id,
            UUID groupId,
            UUID paidById,
            String paidByName,
            UUID paidToId,
            String paidToName,
            BigDecimal amount,
            LocalDateTime createdAt
    ) {
        this.id = id;
        this.groupId = groupId;
        this.paidById = paidById;
        this.paidByName = paidByName;
        this.paidToId = paidToId;
        this.paidToName = paidToName;
        this.amount = amount;
        this.createdAt = createdAt;
    }

    public UUID getId() {
        return id;
    }

    public UUID getGroupId() {
        return groupId;
    }

    public UUID getPaidById() {
        return paidById;
    }

    public String getPaidByName() {
        return paidByName;
    }

    public UUID getPaidToId() {
        return paidToId;
    }

    public String getPaidToName() {
        return paidToName;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
}