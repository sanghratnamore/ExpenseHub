package com.expensehub.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

public record GroupExpenseResponse(
        UUID id,
        String description,
        BigDecimal amount,
        LocalDate expenseDate,
        UUID paidById,
        String paidByName,
        UUID categoryId,
        String categoryName,
        UUID updatedById,
        String updatedByName,
        LocalDateTime updatedAt,
        Integer version,
        LocalDateTime createdAt
) {}