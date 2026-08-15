package com.expensehub.backend.dto;

import java.math.BigDecimal;

public class DashboardResponse {

    private BigDecimal totalExpenses;
    private long expenseCount;
    private BigDecimal thisMonth;
    private BigDecimal today;

    public DashboardResponse() {
    }

    public DashboardResponse(
            BigDecimal totalExpenses,
            long expenseCount,
            BigDecimal thisMonth,
            BigDecimal today
    ) {
        this.totalExpenses = totalExpenses;
        this.expenseCount = expenseCount;
        this.thisMonth = thisMonth;
        this.today = today;
    }

    public BigDecimal getTotalExpenses() {
        return totalExpenses;
    }

    public void setTotalExpenses(BigDecimal totalExpenses) {
        this.totalExpenses = totalExpenses;
    }

    public long getExpenseCount() {
        return expenseCount;
    }

    public void setExpenseCount(long expenseCount) {
        this.expenseCount = expenseCount;
    }

    public BigDecimal getThisMonth() {
        return thisMonth;
    }

    public void setThisMonth(BigDecimal thisMonth) {
        this.thisMonth = thisMonth;
    }

    public BigDecimal getToday() {
        return today;
    }

    public void setToday(BigDecimal today) {
        this.today = today;
    }
}