package com.expensehub.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public record GroupExpenseDetailResponse(
        UUID id,
        String description,
        double amount,
        LocalDate expenseDate,
        UUID paidById,
        String paidByName,
        UUID categoryId,
        String categoryName,
        List<GroupExpenseSplitResponse> splits,
        String updatedByName,
        LocalDateTime updatedAt,
        Integer version
) {}