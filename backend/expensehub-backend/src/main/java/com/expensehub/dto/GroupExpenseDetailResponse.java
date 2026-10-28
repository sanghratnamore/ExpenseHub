package com.expensehub.dto;


import java.time.LocalDate;
import java.util.List;
import java.util.UUID;


public record GroupExpenseDetailResponse(
        UUID id,
        String description,
        Double amount,
        LocalDate expenseDate,
        UUID paidById,
        String paidByName,
        UUID categoryId,
        String categoryName,
        List<GroupExpenseSplitResponse> splits
) {
}