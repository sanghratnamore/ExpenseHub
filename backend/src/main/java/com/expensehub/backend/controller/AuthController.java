package com.expensehub.backend.controller;

import com.expensehub.backend.dto.RegisterRequest;
import com.expensehub.backend.dto.LoginRequest;
import com.expensehub.backend.entity.User;
import com.expensehub.backend.exception.ResourceNotFoundException;
import com.expensehub.backend.repository.UserRepository;
import com.expensehub.backend.service.AuthService;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;


@RestController
@RequestMapping("/api/auth")
public class AuthController {


    private final AuthService authService;
    private final UserRepository userRepository;


    public AuthController(
            AuthService authService,
            UserRepository userRepository
    ) {
        this.authService = authService;
        this.userRepository = userRepository;
    }



    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public User register(
            @Valid @RequestBody RegisterRequest request
    ) {

        return authService.register(request);
    }



    @PostMapping("/login")
    public ResponseEntity<String> login(
            @RequestBody LoginRequest request
    ) {

        String token = authService.login(request);

        return ResponseEntity.ok(token);
    }



    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUser(
            Authentication authentication
    ) {


        String email = authentication.getName();


        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new ResourceNotFoundException(
                                "User not found"
                        )
                );


        return ResponseEntity.ok(
                Map.of(
                        "id", user.getId(),
                        "name", user.getName(),
                        "email", user.getEmail()
                )
        );
    }

}