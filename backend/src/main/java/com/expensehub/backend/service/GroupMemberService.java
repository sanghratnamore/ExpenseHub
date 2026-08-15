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

    public List<GroupMemberResponse> getGroupMembers(UUID groupId) {

        if (!groupRepository.existsById(groupId)) {
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
            UUID userId
    ){

        // 1. Check group exists
        Group group = groupRepository.findById(groupId)
                .orElseThrow(() ->
                        new ResourceNotFoundException(
                                "Group not found"
                        )
                );

        // 2. Check user exists
        User user = userRepository.findById(userId)
                .orElseThrow(() ->
                        new ResourceNotFoundException(
                                "User not found"
                        )
                );

        // 3. Check if already a member
        if (groupMemberRepository.existsByGroupIdAndUserId(
                groupId,
                userId
        )) {

            throw new IllegalArgumentException(
                    "User is already a member of this group"
            );
        }

        // 4. Create membership
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
            UUID userId
    ) {

        // 1. Check group exists
        if (!groupRepository.existsById(groupId)) {

            throw new ResourceNotFoundException(
                    "Group not found"
            );
        }

        // 2. Check membership exists
        if (!groupMemberRepository.existsByGroupIdAndUserId(
                groupId,
                userId
        )) {

            throw new ResourceNotFoundException(
                    "User is not a member of this group"
            );
        }

        // 3. Delete membership
        groupMemberRepository.deleteByGroupIdAndUserId(
                groupId,
                userId
        );
    }
}