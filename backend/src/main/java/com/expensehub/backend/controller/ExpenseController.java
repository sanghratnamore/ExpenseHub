package com.expensehub.backend.controller;

import com.expensehub.backend.entity.Expense;
import com.expensehub.backend.entity.User;
import com.expensehub.backend.repository.UserRepository;
import com.expensehub.backend.service.ExpenseService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import com.expensehub.backend.exception.ResourceNotFoundException;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/expenses")
public class ExpenseController {

    private final ExpenseService expenseService;
    private final UserRepository userRepository;

    public ExpenseController(
            ExpenseService expenseService,
            UserRepository userRepository
    ) {
        this.expenseService = expenseService;
        this.userRepository = userRepository;
    }

    @PostMapping
    public ResponseEntity<Expense> createExpense(
            @RequestBody Expense expense,
            Authentication authentication
    ) {

        String email = authentication.getName();

        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new RuntimeException("User not found"));

        Expense createdExpense =
                expenseService.createExpense(expense, user);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(createdExpense);
    }

    @GetMapping
    public ResponseEntity<List<Expense>> getExpenses(
            Authentication authentication
    ) {

        String email = authentication.getName();

        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new RuntimeException("User not found"));

        List<Expense> expenses =
                expenseService.getUserExpenses(user);

        return ResponseEntity.ok(expenses);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Expense> getExpense(
            @PathVariable UUID id,
            Authentication authentication
    ) {

        String email = authentication.getName();

        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new ResourceNotFoundException("User not found"));

        Expense expense =
                expenseService.getExpenseById(id);

        if (!expense.getUser().getId().equals(user.getId())) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(expense);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Expense> updateExpense(
            @PathVariable UUID id,
            @RequestBody Expense updatedExpense,
            Authentication authentication
    ) {

        String email = authentication.getName();

        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new RuntimeException("User not found"));

        Expense existingExpense =
                expenseService.getExpenseById(id);

        if (!existingExpense.getUser().getId().equals(user.getId())) {
            return ResponseEntity.notFound().build();
        }

        Expense expense =
                expenseService.updateExpense(id, updatedExpense);

        return ResponseEntity.ok(expense);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteExpense(
            @PathVariable UUID id,
            Authentication authentication
    ) {

        String email = authentication.getName();

        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new ResourceNotFoundException("User not found"));

        Expense expense =
                expenseService.getExpenseById(id);

        if (!expense.getUser().getId().equals(user.getId())) {
            return ResponseEntity.notFound().build();
        }

        expenseService.deleteExpense(id);

        return ResponseEntity.noContent().build();
    }
}