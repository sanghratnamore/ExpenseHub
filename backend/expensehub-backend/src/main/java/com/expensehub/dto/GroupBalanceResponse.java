package com.expensehub.dto;

import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GroupBalanceResponse {
    private UUID userId;
    private String userName;
    private BigDecimal totalPaid;
    private BigDecimal totalShare;
    private BigDecimal balance;
    private String status;
}