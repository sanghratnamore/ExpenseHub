package com.expensehub.backend.dto;

import java.math.BigDecimal;
import java.util.UUID;

public class CreateSettlementRequest {

    private UUID paidById;

    private UUID paidToId;

    private BigDecimal amount;

    public CreateSettlementRequest() {
    }

    public UUID getPaidById() {
        return paidById;
    }

    public void setPaidById(UUID paidById) {
        this.paidById = paidById;
    }

    public UUID getPaidToId() {
        return paidToId;
    }

    public void setPaidToId(UUID paidToId) {
        this.paidToId = paidToId;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public void setAmount(BigDecimal amount) {
        this.amount = amount;
    }
}