package com.expensehub.repository;

import com.expensehub.entity.GroupExpense;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface GroupExpenseRepository
        extends JpaRepository<GroupExpense, UUID> {

    List<GroupExpense> findByGroupId(UUID groupId);

    List<GroupExpense> findByGroupIdOrderByExpenseDateDesc(
            UUID groupId
    );

    List<GroupExpense>
    findByGroupIdAndIsDeletedFalseOrderByExpenseDateDesc(
            UUID groupId
    );

    List<GroupExpense>
    findByGroupIdAndIsDeletedTrueAndDeletedAtAfterOrderByDeletedAtDesc(
            UUID groupId,
            LocalDateTime cutoffDate
    );

    @Query("""
            SELECT ge FROM GroupExpense ge
            WHERE ge.group.id = :groupId
              AND ge.id = :expenseId
              AND ge.isDeleted = true
              AND ge.deletedAt > :cutoffDate
            """)
    Optional<GroupExpense> findRestorableExpense(
            @Param("groupId") UUID groupId,
            @Param("expenseId") UUID expenseId,
            @Param("cutoffDate") LocalDateTime cutoffDate
    );

    @Modifying
    @Query("DELETE FROM GroupExpense e WHERE e.group.id = :groupId")
    void deleteByGroupId(@Param("groupId") UUID groupId);

    boolean existsByGroupId(UUID groupId);
}