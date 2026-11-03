package com.expensehub.controller;

import com.expensehub.dto.*;
import com.expensehub.entity.GroupEntity;
import com.expensehub.entity.GroupExpense;
import com.expensehub.entity.User;
import com.expensehub.security.CurrentUser;
import com.expensehub.service.GroupService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/groups")
@RequiredArgsConstructor
public class GroupController {

    private final GroupService groupService;
    private final CurrentUser currentUser;

    @PostMapping
    public ResponseEntity<GroupEntity> createGroup(
            @Valid @RequestBody CreateGroupRequest request
    ) {
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(groupService.createGroup(request));
    }

    @GetMapping
    public ResponseEntity<List<GroupResponse>> getGroups() {
        return ResponseEntity.ok(
                groupService.getGroupsForCurrentUser()
        );
    }

    @PostMapping("/join")
    public ResponseEntity<String> joinGroup(
            @RequestBody Map<String, String> request
    ) {
        String message = groupService.joinGroup(
                request.get("inviteCode")
        );

        return ResponseEntity.ok(message);
    }

    @GetMapping("/{groupId}")
    public ResponseEntity<GroupResponse> getGroup(
            @PathVariable UUID groupId
    ) {
        return ResponseEntity.ok(
                groupService.getGroupForCurrentUser(groupId)
        );
    }

    @DeleteMapping("/{groupId}/leave")
    public ResponseEntity<?> leaveGroup(
            @PathVariable UUID groupId
    ) {
        groupService.leaveGroup(groupId);

        return ResponseEntity.ok(
                Map.of("message", "You left the group")
        );
    }

    @DeleteMapping("/{groupId}")
    public ResponseEntity<?> deleteGroup(
            @PathVariable UUID groupId
    ) {
        groupService.deleteGroup(groupId);

        return ResponseEntity.ok(
                Map.of("message", "Group deleted successfully")
        );
    }

    @PostMapping("/{groupId}/members")
    public ResponseEntity<?> addMembers(
            @PathVariable UUID groupId,
            @RequestBody AddMembersRequest request
    ) {
        groupService.addMembers(groupId, request);

        return ResponseEntity.ok(
                Map.of("message", "Members added successfully")
        );
    }

    @DeleteMapping("/{groupId}/members/{memberId}")
    public ResponseEntity<?> removeMember(
            @PathVariable UUID groupId,
            @PathVariable UUID memberId
    ) {
        groupService.removeMember(groupId, memberId);

        return ResponseEntity.ok(
                Map.of("message", "Member removed successfully")
        );
    }

    @PostMapping("/{groupId}/expenses")
    public GroupExpense addGroupExpense(
            @PathVariable UUID groupId,
            @RequestBody GroupExpenseRequest request
    ) {
        request.setGroupId(groupId);

        return groupService.addGroupExpense(request);
    }

    @GetMapping("/{groupId}/expenses")
    public ResponseEntity<List<GroupExpenseResponse>> getGroupExpenses(
            @PathVariable UUID groupId
    ) {
        return ResponseEntity.ok(
                groupService.getGroupExpenses(groupId)
        );
    }

    @GetMapping("/{groupId}/expenses/{expenseId}")
    public ResponseEntity<GroupExpenseDetailResponse> getGroupExpenseDetail(
            @PathVariable UUID groupId,
            @PathVariable UUID expenseId
    ) {
        return ResponseEntity.ok(
                groupService.getGroupExpenseDetail(
                        groupId,
                        expenseId
                )
        );
    }

    @PutMapping("/{groupId}/expenses/{expenseId}")
    public ResponseEntity<GroupExpense> updateGroupExpense(
            @PathVariable UUID groupId,
            @PathVariable UUID expenseId,
            @RequestBody GroupExpenseRequest request
    ) {
        User user = currentUser.getUser();

        return ResponseEntity.ok(
                groupService.updateGroupExpense(
                        groupId,
                        expenseId,
                        request,
                        user
                )
        );
    }

    @DeleteMapping("/{groupId}/expenses/{expenseId}")
    public ResponseEntity<?> deleteGroupExpense(
            @PathVariable UUID groupId,
            @PathVariable UUID expenseId
    ) {
        User user = currentUser.getUser();

        groupService.deleteGroupExpense(
                groupId,
                expenseId,
                user
        );

        return ResponseEntity.ok(
                Map.of(
                        "message",
                        "Expense moved to Recently Deleted"
                )
        );
    }

    @GetMapping("/{groupId}/expenses/deleted")
    public ResponseEntity<List<GroupExpense>> getDeletedGroupExpenses(
            @PathVariable UUID groupId
    ) {
        return ResponseEntity.ok(
                groupService.getDeletedGroupExpenses(groupId)
        );
    }

    @PostMapping("/{groupId}/expenses/{expenseId}/restore")
    public ResponseEntity<GroupExpense> restoreGroupExpense(
            @PathVariable UUID groupId,
            @PathVariable UUID expenseId
    ) {
        User user = currentUser.getUser();

        return ResponseEntity.ok(
                groupService.restoreGroupExpense(
                        groupId,
                        expenseId,
                        user
                )
        );
    }

    @GetMapping("/{groupId}/balances")
    public ResponseEntity<List<GroupBalanceResponse>> getBalances(
            @PathVariable UUID groupId
    ) {
        return ResponseEntity.ok(
                groupService.getGroupBalances(groupId)
        );
    }

    @GetMapping("/{groupId}/settlements")
    public ResponseEntity<List<SettlementResponse>> getSettlements(
            @PathVariable UUID groupId
    ) {
        return ResponseEntity.ok(
                groupService.getSettlements(groupId)
        );
    }

    @GetMapping("/{groupId}/settlements/simplified")
    public ResponseEntity<List<SettlementResponse>> getSimplifiedSettlements(
            @PathVariable UUID groupId
    ) {
        return ResponseEntity.ok(
                groupService.getSimplifiedSettlements(groupId)
        );
    }

    @PostMapping("/{groupId}/settlements")
    public ResponseEntity<SettlementResponse> settleUp(
            @PathVariable UUID groupId,
            @RequestBody SettlementRequest request
    ) {
        request.setGroupId(groupId);

        return ResponseEntity.ok(
                groupService.settleUp(request)
        );
    }

    @PostMapping("/settle")
    public ResponseEntity<SettlementResponse> settleUp(
            @Valid @RequestBody SettlementRequest request
    ) {
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(groupService.settleUp(request));
    }
}