package com.expensehub.backend.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

public class GroupExpenseResponse {

    private UUID id;
    private BigDecimal amount;
    private String description;
    private String category;
    private LocalDateTime expenseDate;

    private UUID groupId;
    private UUID paidById;
    private String paidByName;

    public GroupExpenseResponse() {
    }

    public GroupExpenseResponse(
            UUID id,
            BigDecimal amount,
            String description,
            String category,
            LocalDateTime expenseDate,
            UUID groupId,
            UUID paidById,
            String paidByName
    ) {
        this.id = id;
        this.amount = amount;
        this.description = description;
        this.category = category;
        this.expenseDate = expenseDate;
        this.groupId = groupId;
        this.paidById = paidById;
        this.paidByName = paidByName;
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
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

    public UUID getGroupId() {
        return groupId;
    }

    public void setGroupId(UUID groupId) {
        this.groupId = groupId;
    }

    public UUID getPaidById() {
        return paidById;
    }

    public void setPaidById(UUID paidById) {
        this.paidById = paidById;
    }

    public String getPaidByName() {
        return paidByName;
    }

    public void setPaidByName(String paidByName) {
        this.paidByName = paidByName;
    }
}