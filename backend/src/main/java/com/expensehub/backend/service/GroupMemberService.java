package com.expensehub.backend.service;

import com.expensehub.backend.dto.GroupMemberResponse;
import com.expensehub.backend.entity.Group;
import com.expensehub.backend.entity.GroupMember;
import com.expensehub.backend.entity.User;
import com.expensehub.backend.exception.ResourceNotFoundException;
import com.expensehub.backend.repository.GroupMemberRepository;
import com.expensehub.backend.repository.GroupRepository;
import com.expensehub.backend.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.expensehub.backend.exception.BadRequestException;
import java.util.List;
import java.util.UUID;

@Service
public class GroupMemberService {

    private final GroupMemberRepository groupMemberRepository;
    private final GroupRepository groupRepository;
    private final UserRepository userRepository;

    public GroupMemberService(
            GroupMemberRepository groupMemberRepository,
            GroupRepository groupRepository,
            UserRepository userRepository
    ) {
        this.groupMemberRepository = groupMemberRepository;
        this.groupRepository = groupRepository;
        this.userRepository = userRepository;
    }

    // =========================================================
    // GET ALL MEMBERS OF A GROUP
    // =========================================================

    public List<GroupMemberResponse> getGroupMembers(
            UUID groupId,
            String currentUserEmail
    ) {

        Group group = getGroup(groupId);

        User currentUser = getUser(currentUserEmail);

        // Only group members can see the member list.
        if (!isMember(groupId, currentUser.getId())) {
            throw new ResourceNotFoundException(
                    "Group not found"
            );
        }

        return groupMemberRepository.findByGroupId(groupId)
                .stream()
                .map(member ->
                        new GroupMemberResponse(
                                member.getUser().getId(),
                                member.getUser().getName(),
                                member.getUser().getEmail(),
                                member.getJoinedAt()
                        )
                )
                .toList();
    }

    // =========================================================
    // ADD MEMBER TO GROUP
    // =========================================================

    @Transactional
    public GroupMemberResponse addMember(
            UUID groupId,
            UUID userId,
            String currentUserEmail
    ) {

        Group group = getGroup(groupId);

        User currentUser = getUser(currentUserEmail);

        // Only the group creator can add members.
        requireGroupCreator(group, currentUser);

        // User being added must exist.
        User user = userRepository.findById(userId)
                .orElseThrow(() ->
                        new ResourceNotFoundException(
                                "User not found"
                        )
                );

        // Prevent duplicate membership.
        if (isMember(groupId, userId)) {
            throw new BadRequestException(
                    "User is already a member of this group"
            );
        }

        GroupMember groupMember = new GroupMember();

        groupMember.setGroup(group);
        groupMember.setUser(user);

        GroupMember savedMember =
                groupMemberRepository.save(groupMember);

        return new GroupMemberResponse(
                savedMember.getUser().getId(),
                savedMember.getUser().getName(),
                savedMember.getUser().getEmail(),
                savedMember.getJoinedAt()
        );
    }

    // =========================================================
    // REMOVE MEMBER FROM GROUP
    // =========================================================

    @Transactional
    public void removeMember(
            UUID groupId,
            UUID userId,
            String currentUserEmail
    ) {

        Group group = getGroup(groupId);

        User currentUser = getUser(currentUserEmail);

        // Only creator can remove members.
        requireGroupCreator(group, currentUser);

        // Creator cannot remove themselves.
        if (group.getCreatedBy()
                .getId()
                .equals(userId)) {

            throw new BadRequestException(
                    "Group creator cannot be removed"
            );
        }

        // Check membership.
        if (!isMember(groupId, userId)) {
            throw new ResourceNotFoundException(
                    "User is not a member of this group"
            );
        }

        groupMemberRepository.deleteByGroupIdAndUserId(
                groupId,
                userId
        );
    }

    // =========================================================
    // HELPER METHODS
    // =========================================================

    private Group getGroup(UUID groupId) {

        return groupRepository.findById(groupId)
                .orElseThrow(() ->
                        new ResourceNotFoundException(
                                "Group not found"
                        )
                );
    }

    private User getUser(String email) {

        return userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new ResourceNotFoundException(
                                "User not found"
                        )
                );
    }

    private boolean isMember(
            UUID groupId,
            UUID userId
    ) {

        return groupMemberRepository
                .existsByGroupIdAndUserId(
                        groupId,
                        userId
                );
    }

    private void requireGroupCreator(
            Group group,
            User currentUser
    ) {

        if (!group.getCreatedBy()
                .getId()
                .equals(currentUser.getId())) {

            throw new ResourceNotFoundException(
                    "Group not found"
            );
        }
    }
}