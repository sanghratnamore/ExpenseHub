package com.expensehub.backend.controller;

import com.expensehub.backend.dto.CreateCustomGroupExpenseRequest;
import com.expensehub.backend.dto.CreateGroupExpenseRequest;
import com.expensehub.backend.dto.GroupBalanceResponse;
import com.expensehub.backend.dto.GroupExpenseParticipantResponse;
import com.expensehub.backend.dto.GroupExpenseResponse;
import com.expensehub.backend.service.GroupExpenseService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/groups")
public class GroupExpenseController {

    private final GroupExpenseService groupExpenseService;

    public GroupExpenseController(
            GroupExpenseService groupExpenseService
    ) {
        this.groupExpenseService = groupExpenseService;
    }

    // =========================================================
    // CREATE EQUAL SPLIT EXPENSE
    // POST /api/groups/{groupId}/expenses
    // =========================================================

    @PostMapping("/{groupId}/expenses")
    public ResponseEntity<GroupExpenseResponse> createExpense(
            @PathVariable UUID groupId,
            @RequestBody CreateGroupExpenseRequest request
    ) {

        GroupExpenseResponse response =
                groupExpenseService.createEqualSplitExpense(
                        groupId,
                        request
                );

        return ResponseEntity.ok(response);
    }


    // =========================================================
    // GET ALL GROUP EXPENSES
    // GET /api/groups/{groupId}/expenses
    // =========================================================

    @GetMapping("/{groupId}/expenses")
    public ResponseEntity<List<GroupExpenseResponse>> getGroupExpenses(
            @PathVariable UUID groupId
    ) {

        return ResponseEntity.ok(
                groupExpenseService.getGroupExpenses(groupId)
        );
    }


    // =========================================================
    // GET EXPENSE PARTICIPANTS
    // GET /api/groups/expenses/{expenseId}/participants
    // =========================================================

    @GetMapping("/expenses/{expenseId}/participants")
    public ResponseEntity<List<GroupExpenseParticipantResponse>>
    getExpenseParticipants(
            @PathVariable UUID expenseId
    ) {

        return ResponseEntity.ok(
                groupExpenseService.getParticipants(expenseId)
        );
    }


    // =========================================================
    // GET GROUP BALANCES
    // GET /api/groups/{groupId}/balances
    // =========================================================

    @GetMapping("/{groupId}/balances")
    public ResponseEntity<List<GroupBalanceResponse>> getGroupBalances(
            @PathVariable UUID groupId
    ) {

        return ResponseEntity.ok(
                groupExpenseService.getGroupBalances(groupId)
        );
    }


    // =========================================================
    // GET GROUP SETTLEMENTS
    // GET /api/groups/{groupId}/settlements
    // =========================================================




    // =========================================================
    // CREATE CUSTOM SPLIT EXPENSE
    // POST /api/groups/{groupId}/expenses/custom
    // =========================================================

    @PostMapping("/{groupId}/expenses/custom")
    public ResponseEntity<GroupExpenseResponse> createCustomExpense(
            @PathVariable UUID groupId,
            @RequestBody CreateCustomGroupExpenseRequest request
    ) {

        GroupExpenseResponse response =
                groupExpenseService.createCustomSplitExpense(
                        groupId,
                        request
                );

        return ResponseEntity.ok(response);
    }
}