package com.expensehub.backend.dto;

import java.math.BigDecimal;

public class MonthlyExpenseResponse {

    private String month;
    private BigDecimal total;

    public MonthlyExpenseResponse(String month, BigDecimal total) {
        this.month = month;
        this.total = total;
    }

    public String getMonth() {
        return month;
    }

    public void setMonth(String month) {
        this.month = month;
    }

    public BigDecimal getTotal() {
        return total;
    }

    public void setTotal(BigDecimal total) {
        this.total = total;
    }
}