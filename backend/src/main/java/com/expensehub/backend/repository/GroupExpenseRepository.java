package com.expensehub.backend.repository;

import com.expensehub.backend.entity.GroupExpense;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface GroupExpenseRepository
        extends JpaRepository<GroupExpense, UUID> {

    List<GroupExpense> findByGroupId(UUID groupId);

    List<GroupExpense> findByPaidById(UUID userId);
}