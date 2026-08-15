package com.expensehub.backend.service;

import com.expensehub.backend.dto.CategoryExpenseResponse;
import com.expensehub.backend.dto.DashboardResponse;
import com.expensehub.backend.dto.MonthlyExpenseResponse;
import com.expensehub.backend.entity.User;
import com.expensehub.backend.repository.ExpenseRepository;

import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Service
public class DashboardService {

    private final ExpenseRepository expenseRepository;

    public DashboardService(ExpenseRepository expenseRepository) {
        this.expenseRepository = expenseRepository;
    }

    public DashboardResponse getDashboard(User user) {

        LocalDateTime now = LocalDateTime.now();

        LocalDate today = now.toLocalDate();

        LocalDateTime startOfToday =
                today.atStartOfDay();

        LocalDateTime startOfTomorrow =
                today.plusDays(1).atStartOfDay();

        LocalDate firstDayOfMonth =
                today.withDayOfMonth(1);

        LocalDateTime startOfMonth =
                firstDayOfMonth.atStartOfDay();

        LocalDateTime startOfNextMonth =
                firstDayOfMonth
                        .plusMonths(1)
                        .atStartOfDay();

        BigDecimal totalExpenses =
                expenseRepository.getTotalExpenses(user.getId());

        long expenseCount =
                expenseRepository.getExpenseCount(user.getId());

        BigDecimal thisMonth =
                expenseRepository.getExpensesBetween(
                        user.getId(),
                        startOfMonth,
                        startOfNextMonth
                );

        BigDecimal todayExpenses =
                expenseRepository.getExpensesBetween(
                        user.getId(),
                        startOfToday,
                        startOfTomorrow
                );

        return new DashboardResponse(
                totalExpenses,
                expenseCount,
                thisMonth,
                todayExpenses
        );
    }

    public List<CategoryExpenseResponse> getCategoryExpenseSummary(
            User user
    ) {

        return expenseRepository.getCategoryExpenseSummary(
                user.getId()
        );
    }

    public List<MonthlyExpenseResponse> getMonthlyExpenseSummary(
            User user
    ) {

        List<Object[]> results =
                expenseRepository.getMonthlyExpenseSummary(
                        user.getId()
                );

        return results.stream()
                .map(row -> new MonthlyExpenseResponse(
                        (String) row[0],
                        (BigDecimal) row[1]
                ))
                .toList();
    }
}