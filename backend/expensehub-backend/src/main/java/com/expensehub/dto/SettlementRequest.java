package com.expensehub.dto;

import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SettlementRequest {

    @NotNull(message = "Group ID is required")
    private UUID groupId;

    @NotNull(message = "Paid by user ID is required")
    private UUID paidBy;

    @NotNull(message = "Paid to user ID is required")
    private UUID paidTo;

    @NotNull(message = "Amount is required")
    private BigDecimal amount;

    @NotNull(message = "Settlement date is required")
    private LocalDate settlementDate;

    private Boolean addToPersonalFinance;
}