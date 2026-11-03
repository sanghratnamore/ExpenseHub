package com.expensehub.repository;

import com.expensehub.entity.AppNotification;
import com.expensehub.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;

import java.util.List;
import java.util.UUID;

public interface AppNotificationRepository
        extends JpaRepository<AppNotification, UUID> {

    List<AppNotification> findByUserOrderByCreatedAtDesc(User user);

    List<AppNotification> findTop20ByUserAndIsReadFalseOrderByCreatedAtDesc(
            User user
    );

    long countByUserAndIsReadFalse(User user);

    void deleteByUser(User user);

    void deleteByIsReadTrueAndCreatedAtBefore(LocalDateTime date);

    void deleteByUserAndIsReadTrueAndCreatedAtBefore(
            User user,
            LocalDateTime date
    );

    boolean existsByUserAndTypeAndCreatedAtBetween(
            User user,
            String type,
            LocalDateTime start,
            LocalDateTime end
    );


}