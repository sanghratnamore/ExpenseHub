package com.expensehub.service;

import com.expensehub.dto.RegisterRequest;
import com.expensehub.dto.RegisterResponse;
import com.expensehub.entity.User;
import com.expensehub.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import com.expensehub.dto.LoginRequest;
import com.expensehub.dto.LoginResponse;
import com.expensehub.security.JwtService;
import com.expensehub.repository.CategoryRepository;




import com.expensehub.dto.ChangePasswordRequest;


@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final JwtService jwtService;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();
    private final CategoryService categoryService;

    public RegisterResponse registerUser(RegisterRequest request) {

        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email is already registered");
        }

        User user = User.builder()
                .name(request.getName())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .phone(request.getPhone())
                .build();

        User savedUser = userRepository.save(user);

        categoryService.createDefaultCategories(savedUser);

        return RegisterResponse.builder()
                .id(savedUser.getId())
                .name(savedUser.getName())
                .email(savedUser.getEmail())
                .phone(savedUser.getPhone())
                .message("User registered successfully")
                .build();
    }

    public LoginResponse loginUser(LoginRequest request) {

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() ->
                        new RuntimeException("Email is not registered")
                );


        boolean isPasswordCorrect = passwordEncoder.matches(
                request.getPassword(),
                user.getPassword()
        );


        if (!isPasswordCorrect) {
            throw new RuntimeException("Invalid password");
        }

        String token = jwtService.generateToken(user.getEmail());

        return LoginResponse.builder()
                .token(token)
                .id(user.getId())
                .name(user.getName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .message("Login successful")
                .build();
    }

    public void updateUserName(String email, String newName) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new RuntimeException("User not found"));

        user.setName(newName);
        userRepository.save(user);
    }

    public void changePassword(String email, ChangePasswordRequest request) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));


        boolean isCurrentPasswordCorrect = passwordEncoder.matches(
                request.currentPassword(),
                user.getPassword()
        );


        if (!isCurrentPasswordCorrect) {
            throw new RuntimeException("Current password is incorrect");
        }


        if (request.newPassword() == null ||
                request.newPassword().length() < 6) {
            throw new RuntimeException(
                    "New password must be at least 6 characters"
            );
        }


        if (!request.newPassword().equals(request.confirmPassword())) {
            throw new RuntimeException("New passwords do not match");
        }


        user.setPassword(
                passwordEncoder.encode(request.newPassword())
        );


        userRepository.save(user);
    }

}