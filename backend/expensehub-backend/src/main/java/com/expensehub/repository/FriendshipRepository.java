package com.expensehub.repository;

import com.expensehub.entity.Friendship;
import com.expensehub.entity.FriendshipStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface FriendshipRepository
        extends JpaRepository<Friendship, UUID> {

    @Query("""
        SELECT f FROM Friendship f
        WHERE f.status = 'ACCEPTED'
        AND (
            f.requester.id = :userId
            OR f.receiver.id = :userId
        )
    """)
    List<Friendship> findAcceptedFriends(
            @Param("userId") UUID userId
    );

    List<Friendship> findByReceiverIdAndStatus(
            UUID receiverId,
            FriendshipStatus status
    );

    List<Friendship> findByRequesterIdAndStatus(
            UUID requesterId,
            FriendshipStatus status
    );

    Optional<Friendship> findByRequesterIdAndReceiverId(
            UUID requesterId,
            UUID receiverId
    );

    boolean existsByRequesterIdAndReceiverId(
            UUID requesterId,
            UUID receiverId
    );
}