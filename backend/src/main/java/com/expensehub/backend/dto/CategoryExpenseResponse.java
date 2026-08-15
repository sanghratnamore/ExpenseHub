package com.expensehub.backend.dto;

import java.math.BigDecimal;

public class CategoryExpenseResponse {

    private String category;
    private BigDecimal total;

    public CategoryExpenseResponse() {
    }

    public CategoryExpenseResponse(
            String category,
            BigDecimal total
    ) {
        this.category = category;
        this.total = total;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public BigDecimal getTotal() {
        return total;
    }

    public void setTotal(BigDecimal total) {
        this.total = total;
    }
}