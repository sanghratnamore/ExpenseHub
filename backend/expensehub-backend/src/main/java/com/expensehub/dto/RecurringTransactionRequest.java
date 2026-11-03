package com.expensehub.dto;


import lombok.Getter;

import java.time.LocalDate;
import java.util.UUID;


@Getter
public class RecurringTransactionRequest {


    private String title;


    private Double amount;


    private String type;


    private String category;


    private String description;


    private String frequency;


    private LocalDate startDate;

    private LocalDate nextDueDate;


    private UUID categoryId;


    public UUID getCategoryId() {
        return categoryId;
    }


    public void setCategoryId(UUID categoryId) {
        this.categoryId = categoryId;
    }


    public void setTitle(String title) {
        this.title = title;
    }


    public void setAmount(Double amount) {
        this.amount = amount;
    }


    public void setType(String type) {
        this.type = type;
    }


    public void setCategory(String category) {
        this.category = category;
    }


    public void setDescription(String description) {
        this.description = description;
    }


    public void setFrequency(String frequency) {
        this.frequency = frequency;
    }


    public void setStartDate(LocalDate startDate) {
        this.startDate = startDate;
    }

}