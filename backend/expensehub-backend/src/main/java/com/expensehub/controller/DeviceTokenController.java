package com.expensehub.controller;

import com.expensehub.dto.DeviceTokenRequest;
import com.expensehub.entity.DeviceToken;
import com.expensehub.entity.User;
import com.expensehub.repository.DeviceTokenRepository;
import com.expensehub.security.CurrentUser;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/notifications")
public class DeviceTokenController {

    private final DeviceTokenRepository deviceTokenRepository;
    private final CurrentUser currentUser;

    public DeviceTokenController(
            DeviceTokenRepository deviceTokenRepository,
            CurrentUser currentUser
    ) {
        this.deviceTokenRepository = deviceTokenRepository;
        this.currentUser = currentUser;
    }

    @PostMapping("/device-token")
    public ResponseEntity<String> saveDeviceToken(
            @RequestBody DeviceTokenRequest request
    ) {
        if (request.getDeviceToken() == null) {
            return ResponseEntity.badRequest()
                    .body("deviceToken is required");
        }

        User user = currentUser.getUser();

        DeviceToken deviceToken = deviceTokenRepository
                .findByDeviceToken(request.getDeviceToken())
                .orElse(new DeviceToken());

        deviceToken.setUserId(user.getId().toString());
        deviceToken.setDeviceToken(request.getDeviceToken());
        deviceToken.setPlatform(request.getPlatform());

        deviceTokenRepository.save(deviceToken);

        return ResponseEntity.ok("Device token saved");
    }
}