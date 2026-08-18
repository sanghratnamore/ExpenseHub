package com.expensehub.backend.controller;

import com.expensehub.backend.dto.GroupResponse;
import com.expensehub.backend.entity.Group;
import com.expensehub.backend.entity.User;
import com.expensehub.backend.exception.ResourceNotFoundException;
import com.expensehub.backend.repository.GroupMemberRepository;
import com.expensehub.backend.repository.GroupRepository;
import com.expensehub.backend.repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import com.expensehub.backend.dto.CreateGroupRequest;
import com.expensehub.backend.service.GroupService;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/groups")
public class GroupController {

    private final GroupRepository groupRepository;
    private final GroupMemberRepository groupMemberRepository;
    private final UserRepository userRepository;
    private final GroupService groupService;

    public GroupController(
            GroupRepository groupRepository,
            GroupMemberRepository groupMemberRepository,
            UserRepository userRepository,
            GroupService groupService
    ) {
        this.groupRepository = groupRepository;
        this.groupMemberRepository = groupMemberRepository;
        this.userRepository = userRepository;
        this.groupService = groupService;
    }

    // =========================================================
    // GET MY GROUPS
    // GET /api/groups
    // =========================================================

    @GetMapping
    public ResponseEntity<List<GroupResponse>> getMyGroups(
            Authentication authentication
    ) {

        String email = authentication.getName();

        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new ResourceNotFoundException(
                                "User not found"
                        )
                );

        List<UUID> groupIds =
                groupMemberRepository.findByUserId(user.getId())
                        .stream()
                        .map(member -> member.getGroup().getId())
                        .toList();

        List<Group> groups =
                groupRepository.findAllById(groupIds);

        List<GroupResponse> response =
                groups.stream()
                        .map(this::convertToResponse)
                        .toList();

        return ResponseEntity.ok(response);
    }

    // =========================================================
// CREATE GROUP
// POST /api/groups
// =========================================================

    @PostMapping
    public ResponseEntity<GroupResponse> createGroup(
            @RequestBody CreateGroupRequest request,
            Authentication authentication
    ) {

        Group savedGroup =
                groupService.createGroup(
                        request,
                        authentication.getName()
                );

        return ResponseEntity.ok(
                convertToResponse(savedGroup)
        );
    }

    // =========================================================
    // CONVERT GROUP ENTITY → SAFE RESPONSE
    // =========================================================

    private GroupResponse convertToResponse(Group group) {

        User creator = group.getCreatedBy();

        return new GroupResponse(
                group.getId(),
                group.getName(),
                group.getCreatedAt(),
                group.getUpdatedAt(),
                creator.getId(),
                creator.getName(),
                creator.getEmail()
        );
    }
}