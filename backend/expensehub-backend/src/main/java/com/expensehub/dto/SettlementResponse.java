package com.expensehub.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SettlementResponse {
    private Long id;
    private Long groupId;
    private String paidByName;
    private String paidToName;
    private BigDecimal amount;
    private LocalDate settlementDate;
    private String message;
}