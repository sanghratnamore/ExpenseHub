package com.expensehub.backend.repository;

import com.expensehub.backend.dto.CategoryExpenseResponse;
import com.expensehub.backend.entity.Expense;
import com.expensehub.backend.entity.User;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public interface ExpenseRepository extends JpaRepository<Expense, UUID> {

    List<Expense> findByUser(User user);

    List<Expense> findByUserId(UUID userId);

    @Query("""
            SELECT COALESCE(SUM(e.amount), 0)
            FROM Expense e
            WHERE e.user.id = :userId
            """)
    BigDecimal getTotalExpenses(
            @Param("userId") UUID userId
    );

    @Query("""
            SELECT COUNT(e)
            FROM Expense e
            WHERE e.user.id = :userId
            """)
    long getExpenseCount(
            @Param("userId") UUID userId
    );

    @Query("""
            SELECT COALESCE(SUM(e.amount), 0)
            FROM Expense e
            WHERE e.user.id = :userId
            AND e.expenseDate >= :start
            AND e.expenseDate < :end
            """)
    BigDecimal getExpensesBetween(
            @Param("userId") UUID userId,
            @Param("start") LocalDateTime start,
            @Param("end") LocalDateTime end
    );

    @Query("""
            SELECT new com.expensehub.backend.dto.CategoryExpenseResponse(
                e.category,
                SUM(e.amount)
            )
            FROM Expense e
            WHERE e.user.id = :userId
            GROUP BY e.category
            ORDER BY SUM(e.amount) DESC
            """)
    List<CategoryExpenseResponse> getCategoryExpenseSummary(
            @Param("userId") UUID userId
    );

    @Query(value = """
            SELECT
                TO_CHAR(e.expense_date, 'YYYY-MM') AS month,
                COALESCE(SUM(e.amount), 0) AS total
            FROM expenses e
            WHERE e.user_id = :userId
            GROUP BY TO_CHAR(e.expense_date, 'YYYY-MM')
            ORDER BY TO_CHAR(e.expense_date, 'YYYY-MM')
            """,
            nativeQuery = true)
    List<Object[]> getMonthlyExpenseSummary(
            @Param("userId") UUID userId
    );
}