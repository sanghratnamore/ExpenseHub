package com.expensehub.backend.service;

import com.expensehub.backend.entity.Expense;
import com.expensehub.backend.entity.User;
import com.expensehub.backend.repository.ExpenseRepository;
import org.springframework.stereotype.Service;
import com.expensehub.backend.exception.ResourceNotFoundException;
import java.util.List;
import java.util.UUID;

@Service
public class ExpenseService {

    private final ExpenseRepository expenseRepository;

    public ExpenseService(ExpenseRepository expenseRepository) {
        this.expenseRepository = expenseRepository;
    }

    public Expense createExpense(Expense expense, User user) {
        expense.setUser(user);
        return expenseRepository.save(expense);
    }

    public List<Expense> getUserExpenses(User user) {
        return expenseRepository.findByUser(user);
    }

    public Expense getExpenseById(UUID expenseId) {
        return expenseRepository.findById(expenseId)
                .orElseThrow(() ->
                        new ResourceNotFoundException("Expense not found"));
    }

    public Expense updateExpense(UUID expenseId, Expense updatedExpense) {
        Expense existingExpense = getExpenseById(expenseId);

        existingExpense.setAmount(updatedExpense.getAmount());
        existingExpense.setCategory(updatedExpense.getCategory());
        existingExpense.setDescription(updatedExpense.getDescription());
        existingExpense.setExpenseDate(updatedExpense.getExpenseDate());

        return expenseRepository.save(existingExpense);
    }

    public void deleteExpense(UUID expenseId) {
        Expense expense = getExpenseById(expenseId);
        expenseRepository.delete(expense);
    }
}