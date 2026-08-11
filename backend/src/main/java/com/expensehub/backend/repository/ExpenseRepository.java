package com.expensehub.backend.repository;

import com.expensehub.backend.entity.Expense;
import com.expensehub.backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface ExpenseRepository extends JpaRepository<Expense, UUID> {

    List<Expense> findByUser(User user);

    List<Expense> findByUserId(UUID userId);
}