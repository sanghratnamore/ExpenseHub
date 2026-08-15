package com.expensehub.backend.controller;

import com.expensehub.backend.dto.AddGroupMembersRequest;
import com.expensehub.backend.entity.Group;
import com.expensehub.backend.entity.GroupMember;
import com.expensehub.backend.entity.User;
import com.expensehub.backend.exception.ResourceNotFoundException;
import com.expensehub.backend.repository.GroupMemberRepository;
import com.expensehub.backend.repository.GroupRepository;
import com.expensehub.backend.repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/groups")
public class GroupController {

    private final GroupRepository groupRepository;
    private final GroupMemberRepository groupMemberRepository;
    private final UserRepository userRepository;

    public GroupController(
            GroupRepository groupRepository,
            GroupMemberRepository groupMemberRepository,
            UserRepository userRepository
    ) {
        this.groupRepository = groupRepository;
        this.groupMemberRepository = groupMemberRepository;
        this.userRepository = userRepository;
    }

    // ==========================================
    // GET MY GROUPS
    // ==========================================

    @GetMapping
    public ResponseEntity<List<Group>> getMyGroups(
            Authentication authentication
    ) {

        String email = authentication.getName();

        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new ResourceNotFoundException("User not found"));

        List<UUID> groupIds =
                groupMemberRepository.findByUserId(user.getId())
                        .stream()
                        .map(member -> member.getGroup().getId())
                        .toList();

        List<Group> groups =
                groupRepository.findAllById(groupIds);

        return ResponseEntity.ok(groups);
    }

    // ==========================================
    // ADD MULTIPLE MEMBERS
    // ==========================================

    @PostMapping("/{groupId}/members")
    public ResponseEntity<List<GroupMember>> addMembers(
            @PathVariable UUID groupId,
            @RequestBody AddGroupMembersRequest request
    ) {

        // 1. Check group exists
        Group group = groupRepository.findById(groupId)
                .orElseThrow(() ->
                        new ResourceNotFoundException(
                                "Group not found"
                        )
                );

        // 2. Validate request
        if (request.getUserIds() == null ||
                request.getUserIds().isEmpty()) {

            throw new IllegalArgumentException(
                    "At least one user ID is required"
            );
        }

        // 3. Remove duplicate IDs
        List<UUID> userIds =
                request.getUserIds()
                        .stream()
                        .distinct()
                        .toList();

        List<GroupMember> addedMembers = new ArrayList<>();

        // 4. Add each user
        for (UUID userId : userIds) {

            // Check user exists
            User user = userRepository.findById(userId)
                    .orElseThrow(() ->
                            new ResourceNotFoundException(
                                    "User not found: " + userId
                            )
                    );

            // Skip if already a member
            if (groupMemberRepository.existsByGroupIdAndUserId(
                    groupId,
                    userId
            )) {
                continue;
            }

            // Create membership
            GroupMember groupMember = new GroupMember();

            groupMember.setGroup(group);
            groupMember.setUser(user);

            GroupMember savedMember =
                    groupMemberRepository.save(groupMember);

            addedMembers.add(savedMember);
        }

        return ResponseEntity.ok(addedMembers);
    }
}