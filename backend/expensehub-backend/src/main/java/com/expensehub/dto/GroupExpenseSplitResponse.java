package com.expensehub.dto;


import java.util.UUID;

public record GroupExpenseSplitResponse(
        UUID id,
        UUID userId,
        String userName,
        Double shareAmount
) {
}