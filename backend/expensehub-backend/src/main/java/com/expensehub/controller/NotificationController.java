package com.expensehub.controller;

import com.expensehub.entity.AppNotification;
import com.expensehub.entity.User;
import com.expensehub.security.CurrentUser;
import com.expensehub.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;
    private final CurrentUser currentUser;

    @GetMapping
    public ResponseEntity<List<AppNotification>> getNotifications() {
        User user = currentUser.getUser();

        return ResponseEntity.ok(
                notificationService.getNotifications(user)
        );
    }

    @GetMapping("/unread-count")
    public ResponseEntity<Map<String, Long>> getUnreadCount() {
        User user = currentUser.getUser();

        return ResponseEntity.ok(
                Map.of("count", notificationService.getUnreadCount(user))
        );
    }

    @PutMapping("/mark-all-read")
    public ResponseEntity<Void> markAllRead() {
        User user = currentUser.getUser();

        notificationService.markAllRead(user);

        return ResponseEntity.ok().build();
    }

    @PutMapping("/{id}/read")
    public ResponseEntity<Void> markAsRead(
            @PathVariable UUID id
    ) {
        User user = currentUser.getUser();
        notificationService.markAsRead(user, id);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteNotification(
            @PathVariable UUID id
    ) {
        User user = currentUser.getUser();
        notificationService.deleteNotification(user, id);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping
    public ResponseEntity<Void> clearAllNotifications() {
        User user = currentUser.getUser();
        notificationService.clearAllNotifications(user);
        return ResponseEntity.ok().build();
    }
}