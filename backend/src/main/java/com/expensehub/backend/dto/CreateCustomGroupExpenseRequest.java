package com.expensehub.backend.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public class CreateCustomGroupExpenseRequest {

    private BigDecimal amount;

    private String description;

    private String category;

    private LocalDateTime expenseDate;

    private UUID paidBy;

    private List<CustomParticipant> participants;

    public CreateCustomGroupExpenseRequest() {
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public void setAmount(BigDecimal amount) {
        this.amount = amount;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public LocalDateTime getExpenseDate() {
        return expenseDate;
    }

    public void setExpenseDate(LocalDateTime expenseDate) {
        this.expenseDate = expenseDate;
    }

    public UUID getPaidBy() {
        return paidBy;
    }

    public void setPaidBy(UUID paidBy) {
        this.paidBy = paidBy;
    }

    public List<CustomParticipant> getParticipants() {
        return participants;
    }

    public void setParticipants(List<CustomParticipant> participants) {
        this.participants = participants;
    }

    public static class CustomParticipant {

        private UUID userId;

        private BigDecimal shareAmount;

        public CustomParticipant() {
        }

        public UUID getUserId() {
            return userId;
        }

        public void setUserId(UUID userId) {
            this.userId = userId;
        }

        public BigDecimal getShareAmount() {
            return shareAmount;
        }

        public void setShareAmount(BigDecimal shareAmount) {
            this.shareAmount = shareAmount;
        }
    }
}