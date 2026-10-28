package com.expensehub.repository;


import com.expensehub.entity.GroupEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;


import java.util.List;
import java.util.Optional;
import java.util.UUID;


public interface GroupRepository
        extends JpaRepository<GroupEntity, UUID> {

    Optional<GroupEntity> findByInviteCode(
            String inviteCode
    );

    @Query("""
        SELECT DISTINCT g
        FROM GroupEntity g
        JOIN FETCH g.members
        WHERE EXISTS (
            SELECT 1
            FROM GroupEntity g2
            JOIN g2.members m2
            WHERE g2.id = g.id
            AND m2.id = :userId
        )
    """)

    List<GroupEntity> findGroupsByMemberId(
            @Param("userId") UUID userId
    );
}