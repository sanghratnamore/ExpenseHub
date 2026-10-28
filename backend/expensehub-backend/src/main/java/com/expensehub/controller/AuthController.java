package com.expensehub.controller;

import com.expensehub.dto.RegisterRequest;
import com.expensehub.dto.RegisterResponse;
import com.expensehub.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.expensehub.dto.LoginRequest;
import com.expensehub.dto.LoginResponse;
import com.expensehub.dto.ChangePasswordRequest;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import java.util.Map;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserService userService;

    @PostMapping("/register")
    public ResponseEntity<?> register(
            @Valid @RequestBody RegisterRequest request
    ) {
        try {
            RegisterResponse response =
                    userService.registerUser(request);


            return ResponseEntity
                    .status(HttpStatus.CREATED)
                    .body(response);
        } catch (RuntimeException e) {
            return ResponseEntity
                    .badRequest()
                    .body(
                            Map.of(
                                    "message",
                                    e.getMessage()
                            )
                    );
        }
    }

    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(
            @Valid @RequestBody LoginRequest request
    ) {
        try {
            LoginResponse response = userService.loginUser(request);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(LoginResponse.builder()
                            .message(e.getMessage())
                            .build());
        }
    }

    @PutMapping("/change-password")
    public ResponseEntity<?> changePassword(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody ChangePasswordRequest request
    ) {
        try {
            userService.changePassword(
                    userDetails.getUsername(),
                    request
            );


            return ResponseEntity.ok(
                    Map.of(
                            "message",
                            "Password changed successfully"
                    )
            );
        } catch (RuntimeException e) {
            return ResponseEntity
                    .badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }


    @PutMapping("/update-profile")
    public ResponseEntity<?> updateProfile(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody Map<String, String> request
    ) {
        try {
            String newName = request.get("name");

            if (newName == null || newName.trim().isEmpty()) {
                return ResponseEntity
                        .badRequest()
                        .body(Map.of("message", "Name is required"));
            }

            userService.updateUserName(
                    userDetails.getUsername(),
                    newName.trim()
            );

            return ResponseEntity.ok(
                    Map.of(
                            "message",
                            "Profile updated successfully"
                    )
            );
        } catch (RuntimeException e) {
            return ResponseEntity
                    .badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }
}