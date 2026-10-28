package com.expensehub.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GroupExpenseRequest {

    @NotNull(message = "Group ID is required")
    private UUID groupId;

    @NotBlank(message = "Description is required")
    private String description;

    @NotNull(message = "Amount is required")
    private BigDecimal amount;

    @NotNull(message = "Expense date is required")
    private LocalDate expenseDate;

    @NotNull(message = "Paid by user ID is required")
    private UUID paidBy;

    @NotNull(message = "Member IDs are required")
    private List<UUID> memberIds;

    private UUID categoryId;
}