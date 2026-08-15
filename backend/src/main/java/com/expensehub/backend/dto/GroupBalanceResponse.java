package com.expensehub.backend.dto;

import java.math.BigDecimal;
import java.util.UUID;

public class GroupBalanceResponse {

    private UUID userId;
    private String userName;
    private BigDecimal totalPaid;
    private BigDecimal totalShare;
    private BigDecimal balance;

    public GroupBalanceResponse(
            UUID userId,
            String userName,
            BigDecimal totalPaid,
            BigDecimal totalShare,
            BigDecimal balance
    ) {
        this.userId = userId;
        this.userName = userName;
        this.totalPaid = totalPaid;
        this.totalShare = totalShare;
        this.balance = balance;
    }

    public UUID getUserId() {
        return userId;
    }

    public String getUserName() {
        return userName;
    }

    public BigDecimal getTotalPaid() {
        return totalPaid;
    }

    public BigDecimal getTotalShare() {
        return totalShare;
    }

    public BigDecimal getBalance() {
        return balance;
    }
}