package com.expensehub.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SettlementResponse {
    private UUID id;
    private UUID groupId;
    private String paidByName;
    private String paidToName;
    private BigDecimal amount;
    private LocalDate settlementDate;
    private String message;
    private UUID paidById;
    private UUID paidToId;
    private LocalDateTime settledAt;
}