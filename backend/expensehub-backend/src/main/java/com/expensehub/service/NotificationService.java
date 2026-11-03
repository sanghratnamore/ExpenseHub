package com.expensehub.service;

import com.expensehub.entity.AppNotification;
import com.expensehub.entity.User;
import com.expensehub.repository.AppNotificationRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final AppNotificationRepository notificationRepository;

    public void createNotification(
            User user,
            String type,
            String title,
            String message,
            UUID groupId,
            UUID expenseId,
            UUID settlementId
    ) {
        notificationRepository.save(
                AppNotification.builder()
                        .user(user)
                        .type(type)
                        .title(title)
                        .message(message)
                        .groupId(groupId)
                        .expenseId(expenseId)
                        .settlementId(settlementId)
                        .isRead(false)
                        .createdAt(LocalDateTime.now())
                        .build()
        );
    }

    @Transactional
    public List<AppNotification> getNotifications(User user) {
        deleteOldReadNotifications(user);

        return notificationRepository.findByUserOrderByCreatedAtDesc(user);
    }

    public long getUnreadCount(User user) {
        return notificationRepository.countByUserAndIsReadFalse(user);
    }

    public void markAllRead(User user) {
        List<AppNotification> notifications =
                notificationRepository.findByUserOrderByCreatedAtDesc(user);

        notifications.forEach(notification -> notification.setRead(true));
        notificationRepository.saveAll(notifications);
    }


    @Transactional
    public void markAsRead(User user, UUID notificationId) {
        AppNotification notification = notificationRepository
                .findById(notificationId)
                .orElseThrow(() -> new RuntimeException("Notification not found"));

        if (!notification.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("You cannot update this notification");
        }

        notification.setRead(true);
        notificationRepository.save(notification);
    }

    @Transactional
    public void deleteNotification(User user, UUID notificationId) {
        AppNotification notification = notificationRepository
                .findById(notificationId)
                .orElseThrow(() -> new RuntimeException("Notification not found"));

        if (!notification.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("You cannot delete this notification");
        }

        notificationRepository.delete(notification);
    }

    @Transactional
    public void clearAllNotifications(User user) {
        notificationRepository.deleteByUser(user);
    }

    @Transactional
    public void deleteOldReadNotifications(User user) {
        LocalDateTime sevenDaysAgo =
                LocalDateTime.now().minusDays(7);

        notificationRepository
                .deleteByUserAndIsReadTrueAndCreatedAtBefore(
                        user,
                        sevenDaysAgo
                );
    }

    @Transactional
    public void createBudgetNotificationIfNotSent(
            User user,
            String type,
            String title,
            String message
    ) {
        LocalDateTime now = LocalDateTime.now();

        LocalDateTime monthStart = now
                .withDayOfMonth(1)
                .toLocalDate()
                .atStartOfDay();

        LocalDateTime monthEnd = monthStart.plusMonths(1);

        boolean alreadySent = notificationRepository
                .existsByUserAndTypeAndCreatedAtBetween(
                        user,
                        type,
                        monthStart,
                        monthEnd
                );

        if (alreadySent) return;

        createNotification(
                user,
                type,
                title,
                message,
                null,
                null,
                null
        );
    }

}