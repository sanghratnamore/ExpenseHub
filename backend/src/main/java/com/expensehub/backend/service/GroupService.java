package com.expensehub.backend.service;

import com.expensehub.backend.dto.CreateGroupRequest;
import com.expensehub.backend.entity.Group;
import com.expensehub.backend.entity.GroupMember;
import com.expensehub.backend.entity.User;
import com.expensehub.backend.exception.ResourceNotFoundException;
import com.expensehub.backend.repository.GroupMemberRepository;
import com.expensehub.backend.repository.GroupRepository;
import com.expensehub.backend.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class GroupService {

    private final GroupRepository groupRepository;
    private final GroupMemberRepository groupMemberRepository;
    private final UserRepository userRepository;

    public GroupService(
            GroupRepository groupRepository,
            GroupMemberRepository groupMemberRepository,
            UserRepository userRepository
    ) {
        this.groupRepository = groupRepository;
        this.groupMemberRepository = groupMemberRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public Group createGroup(
            CreateGroupRequest request,
            String email
    ) {

        if (request.getName() == null ||
                request.getName().trim().isEmpty()) {

            throw new IllegalArgumentException(
                    "Group name is required"
            );
        }

        User user =
                userRepository.findByEmail(email)
                        .orElseThrow(() ->
                                new ResourceNotFoundException(
                                        "User not found"
                                )
                        );

        Group group = new Group();

        group.setName(request.getName().trim());
        group.setCreatedBy(user);

        Group savedGroup =
                groupRepository.save(group);

        GroupMember member = new GroupMember();

        member.setGroup(savedGroup);
        member.setUser(user);

        groupMemberRepository.save(member);

        return savedGroup;
    }
}