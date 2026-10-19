package com.expensehub.controller;

import com.expensehub.dto.CreateGroupRequest;
import com.expensehub.dto.GroupBalanceResponse;
import com.expensehub.dto.GroupExpenseRequest;
import com.expensehub.entity.GroupEntity;
import com.expensehub.entity.GroupExpense;
import com.expensehub.service.GroupService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.expensehub.dto.SettlementRequest;
import com.expensehub.dto.SettlementResponse;

import java.util.List;

@RestController
@RequestMapping("/api/groups")
@RequiredArgsConstructor
public class GroupController {

    private final GroupService groupService;

    @PostMapping
    public ResponseEntity<GroupEntity> createGroup(
            @Valid @RequestBody CreateGroupRequest request
    ) {
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(groupService.createGroup(request));
    }

    @PostMapping("/expenses")
    public ResponseEntity<GroupExpense> addGroupExpense(
            @Valid @RequestBody GroupExpenseRequest request
    ) {
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(groupService.addGroupExpense(request));
    }

    @GetMapping("/{groupId}/balances")
    public ResponseEntity<List<GroupBalanceResponse>> getBalances(
            @PathVariable Long groupId
    ) {
        return ResponseEntity.ok(groupService.getGroupBalances(groupId));
    }

    @PostMapping("/settle")
    public ResponseEntity<SettlementResponse> settleUp(
            @Valid @RequestBody SettlementRequest request
    ) {
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(groupService.settleUp(request));
    }

    @GetMapping("/{groupId}/settlements")
    public ResponseEntity<List<SettlementResponse>> getSettlements(
            @PathVariable Long groupId
    ) {
        return ResponseEntity.ok(groupService.getSettlements(groupId));
    }
}