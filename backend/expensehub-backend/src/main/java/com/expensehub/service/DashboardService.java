package com.expensehub.service;


import com.expensehub.dto.DashboardResponse;
import lombok.RequiredArgsConstructor;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;


@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class DashboardService {


    private final ExpenseCalculationEngine
            expenseCalculationEngine;


    public DashboardResponse getMonthlyDashboard(
            UUID userId,
            int year,
            int month
    ) {
        return expenseCalculationEngine
                .calculateMonthlyDashboard(
                        userId,
                        year,
                        month
                );
    }
}