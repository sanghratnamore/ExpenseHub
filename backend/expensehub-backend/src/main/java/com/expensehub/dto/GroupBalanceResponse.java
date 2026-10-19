package com.expensehub.dto;

import lombok.*;

import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GroupBalanceResponse {
    private Long userId;
    private String userName;
    private BigDecimal totalPaid;
    private BigDecimal totalShare;
    private BigDecimal balance;
    private String status;
}