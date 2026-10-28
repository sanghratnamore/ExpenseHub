package com.expensehub.repository;

import com.expensehub.entity.GroupMember;
import com.expensehub.entity.GroupRole;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface GroupMemberRepository
        extends JpaRepository<GroupMember, UUID> {

    boolean existsByGroupIdAndUserIdAndActiveTrue(
            UUID groupId,
            UUID userId
    );

    boolean existsByGroupIdAndUserIdAndRoleAndActiveTrue(
            UUID groupId,
            UUID userId,
            GroupRole role
    );

    Optional<GroupMember> findByGroupIdAndUserId(
            UUID groupId,
            UUID userId
    );

    List<GroupMember> findByGroupIdAndActiveTrue(
            UUID groupId
    );

    List<GroupMember> findByUserIdAndActiveTrue(
            UUID userId
    );


    long countByGroupIdAndRoleAndActiveTrue(
            UUID groupId,
            GroupRole role
    );

    @Modifying
    @Query("DELETE FROM GroupExpense e WHERE e.group.id = :groupId")
    void deleteByGroupId(@Param("groupId") UUID groupId);
}