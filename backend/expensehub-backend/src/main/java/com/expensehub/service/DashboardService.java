package com.expensehub.service;

import com.expensehub.dto.DashboardResponse;
import com.expensehub.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class DashboardService {

    private final TransactionRepository transactionRepository;

    public DashboardResponse getMonthlyDashboard(Long userId, int year, int month) {

        LocalDate startDate = LocalDate.of(year, month, 1);
        LocalDate endDate = startDate.withDayOfMonth(startDate.lengthOfMonth());

        BigDecimal totalIncome = transactionRepository.getTotalByTypeAndDateRange(
                userId, "INCOME", startDate, endDate
        );

        BigDecimal totalExpense = transactionRepository.getTotalByTypeAndDateRange(
                userId, "EXPENSE", startDate, endDate
        );

        BigDecimal savings = totalIncome.subtract(totalExpense);

        List<Object[]> rows = transactionRepository.getCategoryWiseExpense(
                userId, startDate, endDate
        );

        List<DashboardResponse.CategorySummary> categorySummary = new ArrayList<>();

        for (Object[] row : rows) {
            String categoryName = (String) row[0];
            BigDecimal totalAmount = new BigDecimal(row[1].toString());

            categorySummary.add(
                    DashboardResponse.CategorySummary.builder()
                            .categoryName(categoryName)
                            .totalAmount(totalAmount)
                            .build()
            );
        }

        return DashboardResponse.builder()
                .totalIncome(totalIncome)
                .totalExpense(totalExpense)
                .savings(savings)
                .categorySummary(categorySummary)
                .build();
    }
}