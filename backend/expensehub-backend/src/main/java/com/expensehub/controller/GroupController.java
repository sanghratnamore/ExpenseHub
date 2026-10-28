package com.expensehub.controller;

import com.expensehub.dto.*;
import com.expensehub.entity.GroupEntity;
import com.expensehub.entity.GroupExpense;
import com.expensehub.service.GroupService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.DeleteMapping;

import java.util.Map;

import java.util.List;
import java.util.UUID;

import org.springframework.web.bind.annotation.*;

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

    @GetMapping("/{groupId}/balances")
    public ResponseEntity<List<GroupBalanceResponse>> getBalances(
            @PathVariable UUID groupId
    ) {
        return ResponseEntity.ok(groupService.getGroupBalances(groupId));
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

    @GetMapping
    public ResponseEntity<List<GroupResponse>> getGroups() {
        return ResponseEntity.ok(
                groupService.getGroupsForCurrentUser()
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

    @GetMapping("/{groupId}")
    public ResponseEntity<GroupResponse> getGroup(
            @PathVariable UUID groupId
    ) {
        return ResponseEntity.ok(
                groupService.getGroupForCurrentUser(groupId)
        );
    }

    @PostMapping("/{groupId}/members")
    public ResponseEntity<?> addMembers(
            @PathVariable UUID groupId,
            @RequestBody AddMembersRequest request
    ) {
        groupService.addMembers(
                groupId,
                request
        );

        return ResponseEntity.ok(
                Map.of(
                        "message",
                        "Members added successfully"
                )
        );
    }

    @DeleteMapping("/{groupId}/members/{memberId}")
    public ResponseEntity<?> removeMember(
            @PathVariable UUID groupId,
            @PathVariable UUID memberId
    ) {
        groupService.removeMember(
                groupId,
                memberId
        );

        return ResponseEntity.ok(
                Map.of(
                        "message",
                        "Member removed successfully"
                )
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

    @GetMapping("/{groupId}/settlements")
    public ResponseEntity<List<SettlementResponse>> getSettlements(
            @PathVariable UUID groupId
    ) {
        return ResponseEntity.ok(groupService.getSettlements(groupId));
    }

    @GetMapping("/{groupId}/settlement-suggestions")
    public List<SettlementResponse> getSettlementSuggestions(
            @PathVariable UUID groupId
    ) {
        return groupService.getSimplifiedSettlements(groupId);
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

    @GetMapping("/{groupId}/settlements/simplified")
    public ResponseEntity<List<SettlementResponse>>
    getSimplifiedSettlements(
            @PathVariable UUID groupId
    ) {
        return ResponseEntity.ok(
                groupService.getSimplifiedSettlements(
                        groupId
                )
        );
    }

    @PutMapping("/{groupId}/expenses/{expenseId}")
    public GroupExpense updateGroupExpense(
            @PathVariable UUID groupId,
            @PathVariable UUID expenseId,
            @RequestBody GroupExpenseRequest request
    ) {
        request.setGroupId(groupId);

        return groupService.updateGroupExpense(
                expenseId,
                request
        );
    }


    @DeleteMapping("/{groupId}/expenses/{expenseId}")
    public ResponseEntity<Void> deleteGroupExpense(
            @PathVariable UUID groupId,
            @PathVariable UUID expenseId
    ) {
        groupService.deleteGroupExpense(
                groupId,
                expenseId
        );


        return ResponseEntity.noContent().build();
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

    @PostMapping("/join")
    public ResponseEntity<String> joinGroup(
            @RequestBody Map<String, String> request
    ) {
        String message =
                groupService.joinGroup(
                        request.get("inviteCode")
                );

        return ResponseEntity.ok(message);
    }
}