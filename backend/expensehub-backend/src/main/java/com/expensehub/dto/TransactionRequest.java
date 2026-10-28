package com.expensehub.dto;

import jakarta.validation.constraints.NotBlank;
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
public class TransactionRequest {

    @NotBlank(message = "Transaction type is required")
    private String type;

    @NotNull(message = "Amount is required")
    private BigDecimal amount;

    private String description;

    @NotNull(message = "Date is required")
    private LocalDate date;

    @NotNull(message = "User ID is required")
    private UUID userId;

    @NotNull(message = "Category ID is required")
    private UUID categoryId;

    private Boolean isRecurring;

    private String recurringFrequency;
}