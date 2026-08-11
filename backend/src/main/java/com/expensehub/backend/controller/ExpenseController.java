package com.expensehub.backend.controller;

import com.expensehub.backend.dto.ExpenseRequest;
import com.expensehub.backend.dto.ExpenseResponse;
import com.expensehub.backend.entity.Expense;
import com.expensehub.backend.entity.User;
import com.expensehub.backend.exception.ResourceNotFoundException;
import com.expensehub.backend.repository.UserRepository;
import com.expensehub.backend.service.ExpenseService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

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
    public ResponseEntity<ExpenseResponse> createExpense(
            @Valid @RequestBody ExpenseRequest request,
            Authentication authentication
    ) {

        String email = authentication.getName();

        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new ResourceNotFoundException("User not found"));

        ExpenseResponse createdExpense =
                expenseService.createExpense(request, user);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(createdExpense);
    }

    @GetMapping
    public ResponseEntity<List<ExpenseResponse>> getExpenses(
            Authentication authentication
    ) {

        String email = authentication.getName();

        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new ResourceNotFoundException("User not found"));

        List<ExpenseResponse> expenses =
                expenseService.getUserExpenses(user);

        return ResponseEntity.ok(expenses);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ExpenseResponse> getExpense(
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

        /*
         * Convert the entity to a safe response.
         */
        ExpenseResponse response =
                expenseService.convertToResponseForController(expense);

        return ResponseEntity.ok(response);
    }

    @PutMapping("/{id}")
    public ResponseEntity<ExpenseResponse> updateExpense(
            @PathVariable UUID id,
            @Valid @RequestBody ExpenseRequest request,
            Authentication authentication
    ) {

        String email = authentication.getName();

        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new ResourceNotFoundException("User not found"));

        Expense existingExpense =
                expenseService.getExpenseById(id);

        if (!existingExpense.getUser().getId().equals(user.getId())) {
            return ResponseEntity.notFound().build();
        }

        ExpenseResponse response =
                expenseService.updateExpense(id, request);

        return ResponseEntity.ok(response);
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