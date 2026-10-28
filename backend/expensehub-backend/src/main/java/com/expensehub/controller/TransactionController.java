package com.expensehub.controller;

import com.expensehub.dto.TransactionRequest;
import com.expensehub.entity.Transaction;
import com.expensehub.service.TransactionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/transactions")
@RequiredArgsConstructor
public class TransactionController {

    private final TransactionService transactionService;

    @PostMapping
    public ResponseEntity<Transaction> createTransaction(
            @Valid @RequestBody TransactionRequest request
    ) {
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(transactionService.createTransaction(request));
    }

    @GetMapping
    public ResponseEntity<List<Transaction>> getTransactions() {
        return ResponseEntity.ok(
                transactionService.getTransactionsByUser()
        );
    }

    @PutMapping("/{transactionId}")
    public ResponseEntity<Transaction> updateTransaction(
            @PathVariable UUID transactionId,
            @Valid @RequestBody TransactionRequest request
    ) {
        return ResponseEntity.ok(
                transactionService.updateTransaction(transactionId, request)
        );
    }

    @DeleteMapping("/{transactionId}")
    public ResponseEntity<String> deleteTransaction(
            @PathVariable UUID transactionId
    ) {
        transactionService.deleteTransaction(transactionId);
        return ResponseEntity.ok("Transaction deleted successfully");
    }
}