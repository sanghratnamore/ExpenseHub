package com.expensehub.controller;


import com.expensehub.dto.RecurringTransactionRequest;
import com.expensehub.entity.RecurringTransaction;
import com.expensehub.service.RecurringTransactionService;


import lombok.RequiredArgsConstructor;


import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;


import java.util.List;
import java.util.UUID;


@RestController
@RequestMapping("/api/recurring-transactions")
@RequiredArgsConstructor
public class RecurringTransactionController {


    private final RecurringTransactionService
            recurringTransactionService;


    @PostMapping
    public ResponseEntity<RecurringTransaction>
    createRecurringTransaction(
            @RequestBody RecurringTransactionRequest request
    ) {


        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(
                        recurringTransactionService
                                .createRecurringTransaction(request)
                );
    }


    @GetMapping
    public ResponseEntity<List<RecurringTransaction>>
    getRecurringTransactions() {


        return ResponseEntity.ok(
                recurringTransactionService
                        .getRecurringTransactionsByUser()
        );
    }


    @DeleteMapping("/{id}")
    public ResponseEntity<String>
    deleteRecurringTransaction(
            @PathVariable UUID id
    ) {


        recurringTransactionService
                .deleteRecurringTransaction(id);


        return ResponseEntity.ok(
                "Recurring transaction deleted"
        );
    }

    @PutMapping("/{id}/pause")
    public ResponseEntity<String> pauseRecurringTransaction(
            @PathVariable UUID id
    ) {
        recurringTransactionService.pauseRecurringTransaction(id);
        return ResponseEntity.ok("Recurring transaction paused");
    }

    @PutMapping("/{id}/resume")
    public ResponseEntity<String> resumeRecurringTransaction(
            @PathVariable UUID id
    ) {
        recurringTransactionService.resumeRecurringTransaction(id);
        return ResponseEntity.ok("Recurring transaction resumed");
    }

    @PutMapping("/{id}")
    public ResponseEntity<RecurringTransaction> updateRecurringTransaction(
            @PathVariable UUID id,
            @RequestBody RecurringTransactionRequest request
    ) {
        return ResponseEntity.ok(
                recurringTransactionService.updateRecurringTransaction(
                        id,
                        request
                )
        );
    }
}