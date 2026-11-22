package com.expensehub.service;


import com.expensehub.dto.DashboardResponse;
import lombok.RequiredArgsConstructor;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.expensehub.security.CurrentUser;
import com.expensehub.entity.User;


@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class DashboardService {

    private final CurrentUser currentUser;
    private final ExpenseCalculationEngine
            expenseCalculationEngine;

    public DashboardResponse getMonthlyDashboardForCurrentUser(int year, int month) {
        User user = currentUser.getUser();
        return expenseCalculationEngine.calculateMonthlyDashboard(user.getId(), year, month);
    }

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