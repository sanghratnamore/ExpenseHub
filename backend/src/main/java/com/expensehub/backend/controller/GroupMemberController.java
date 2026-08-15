package com.expensehub.backend.controller;

import com.expensehub.backend.dto.GroupMemberResponse;
import com.expensehub.backend.service.GroupMemberService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/groups")
public class GroupMemberController {

    private final GroupMemberService groupMemberService;

    public GroupMemberController(
            GroupMemberService groupMemberService
    ) {
        this.groupMemberService = groupMemberService;
    }

    // =========================================================
    // GET ALL MEMBERS
    // GET /api/groups/{groupId}/members
    // =========================================================

    @GetMapping("/{groupId}/members")
    public ResponseEntity<List<GroupMemberResponse>> getGroupMembers(
            @PathVariable UUID groupId
    ) {

        return ResponseEntity.ok(
                groupMemberService.getGroupMembers(groupId)
        );
    }

    // =========================================================
    // ADD MEMBER
    // POST /api/groups/{groupId}/members/{userId}
    // =========================================================

    @PostMapping("/{groupId}/members/{userId}")
    public ResponseEntity<GroupMemberResponse> addMember(
            @PathVariable UUID groupId,
            @PathVariable UUID userId
    ) {

        return ResponseEntity.ok(
                groupMemberService.addMember(
                        groupId,
                        userId
                )
        );
    }

    // =========================================================
    // REMOVE MEMBER
    // DELETE /api/groups/{groupId}/members/{userId}
    // =========================================================

    @DeleteMapping("/{groupId}/members/{userId}")
    public ResponseEntity<Void> removeMember(
            @PathVariable UUID groupId,
            @PathVariable UUID userId
    ) {

        groupMemberService.removeMember(
                groupId,
                userId
        );

        return ResponseEntity.noContent().build();
    }
}