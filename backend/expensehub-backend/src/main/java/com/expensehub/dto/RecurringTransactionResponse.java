package com.expensehub.dto;


import java.time.LocalDate;
import java.util.UUID;


public class RecurringTransactionResponse {


    private UUID id;


    private String title;


    private Double amount;


    private String type;


    private String category;


    private String description;


    private String frequency;


    private LocalDate startDate;


    private LocalDate nextDueDate;


    private boolean active;


    public UUID getId() {
        return id;
    }


    public void setId(UUID id) {
        this.id = id;
    }


    public String getTitle() {
        return title;
    }


    public void setTitle(String title) {
        this.title = title;
    }


    public Double getAmount() {
        return amount;
    }


    public void setAmount(Double amount) {
        this.amount = amount;
    }


    public String getType() {
        return type;
    }


    public void setType(String type) {
        this.type = type;
    }


    public String getCategory() {
        return category;
    }


    public void setCategory(String category) {
        this.category = category;
    }


    public String getDescription() {
        return description;
    }


    public void setDescription(String description) {
        this.description = description;
    }


    public String getFrequency() {
        return frequency;
    }


    public void setFrequency(String frequency) {
        this.frequency = frequency;
    }


    public LocalDate getStartDate() {
        return startDate;
    }


    public void setStartDate(LocalDate startDate) {
        this.startDate = startDate;
    }


    public LocalDate getNextDueDate() {
        return nextDueDate;
    }


    public void setNextDueDate(LocalDate nextDueDate) {
        this.nextDueDate = nextDueDate;
    }


    public boolean isActive() {
        return active;
    }


    public void setActive(boolean active) {
        this.active = active;
    }
}