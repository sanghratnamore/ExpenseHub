package com.expensehub.backend.service;

import com.expensehub.backend.dto.ExpenseRequest;
import com.expensehub.backend.dto.ExpenseResponse;
import com.expensehub.backend.dto.UserResponse;
import com.expensehub.backend.entity.Expense;
import com.expensehub.backend.entity.User;
import com.expensehub.backend.exception.ResourceNotFoundException;
import com.expensehub.backend.repository.ExpenseRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
public class ExpenseService {

    private final ExpenseRepository expenseRepository;

    public ExpenseService(ExpenseRepository expenseRepository) {
        this.expenseRepository = expenseRepository;
    }

    public ExpenseResponse createExpense(
            ExpenseRequest request,
            User user
    ) {

        Expense expense = new Expense();

        expense.setAmount(request.getAmount());
        expense.setCategory(request.getCategory());
        expense.setDescription(request.getDescription());
        expense.setExpenseDate(request.getExpenseDate());
        expense.setUser(user);

        Expense savedExpense = expenseRepository.save(expense);

        return convertToResponse(savedExpense);
    }

    public List<ExpenseResponse> getUserExpenses(User user) {

        return expenseRepository.findByUser(user)
                .stream()
                .map(this::convertToResponse)
                .toList();
    }

    public Expense getExpenseById(UUID expenseId) {

        return expenseRepository.findById(expenseId)
                .orElseThrow(() ->
                        new ResourceNotFoundException("Expense not found"));
    }

    public ExpenseResponse updateExpense(
            UUID expenseId,
            ExpenseRequest request
    ) {

        Expense existingExpense = getExpenseById(expenseId);

        existingExpense.setAmount(request.getAmount());
        existingExpense.setCategory(request.getCategory());
        existingExpense.setDescription(request.getDescription());
        existingExpense.setExpenseDate(request.getExpenseDate());

        Expense updatedExpense =
                expenseRepository.save(existingExpense);

        return convertToResponse(updatedExpense);
    }

    public void deleteExpense(UUID expenseId) {

        Expense expense = getExpenseById(expenseId);

        expenseRepository.delete(expense);
    }

    public ExpenseResponse convertToResponseForController(Expense expense) {
        return convertToResponse(expense);
    }
    private ExpenseResponse convertToResponse(Expense expense) {

        User user = expense.getUser();

        UserResponse userResponse = new UserResponse(
                user.getId().toString(),
                user.getName(),
                user.getEmail()
        );

        return new ExpenseResponse(
                expense.getId(),
                expense.getAmount(),
                expense.getCategory(),
                expense.getDescription(),
                expense.getExpenseDate(),
                expense.getCreatedAt(),
                expense.getUpdatedAt(),
                userResponse
        );
    }
}