package com.expensehub.service;

import com.expensehub.entity.DeviceToken;
import com.expensehub.repository.DeviceTokenRepository;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class PushNotificationService {

    private final DeviceTokenRepository deviceTokenRepository;

    public PushNotificationService(
            DeviceTokenRepository deviceTokenRepository
    ) {
        this.deviceTokenRepository = deviceTokenRepository;
    }

    public void sendToUsers(
            List<String> userIds,
            String title,
            String body,
            String groupId,
            String expenseId,
            String type
    ) {
        for (String userId : userIds) {
            List<DeviceToken> tokens =
                    deviceTokenRepository.findByUserId(userId);

            for (DeviceToken deviceToken : tokens) {
                Message.Builder messageBuilder = Message.builder()
                        .setToken(deviceToken.getDeviceToken())
                        .setNotification(
                                Notification.builder()
                                        .setTitle(title)
                                        .setBody(body)
                                        .build()
                        );

                if (type != null) {
                    messageBuilder.putData("type", type);
                }

                if (groupId != null) {
                    messageBuilder.putData("groupId", groupId);
                }

                if (expenseId != null) {
                    messageBuilder.putData("expenseId", expenseId);
                }

                try {
                    String firebaseResponse = FirebaseMessaging
                            .getInstance()
                            .send(messageBuilder.build());

                    System.out.println(
                            "FIREBASE SEND SUCCESS: "
                                    + firebaseResponse
                    );
                } catch (Exception e) {
                    System.out.println("FIREBASE SEND FAILED");
                    e.printStackTrace();
                }
            }
        }
    }
}