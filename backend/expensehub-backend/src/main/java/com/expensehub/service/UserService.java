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
import com.expensehub.entity.Category;
import com.expensehub.repository.CategoryRepository;
import java.util.List;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final CategoryRepository categoryRepository;
    private final JwtService jwtService;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();
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
        createDefaultCategories(savedUser);

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
                .orElseThrow(() -> new RuntimeException("Invalid email or password"));

        boolean isPasswordCorrect = passwordEncoder.matches(
                request.getPassword(),
                user.getPassword()
        );

        if (!isPasswordCorrect) {
            throw new RuntimeException("Invalid email or password");
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

    private void createDefaultCategories(User user) {
        List<Category> defaultCategories = List.of(
                Category.builder().name("Food").type("EXPENSE").user(user).build(),
                Category.builder().name("Travel").type("EXPENSE").user(user).build(),
                Category.builder().name("Shopping").type("EXPENSE").user(user).build(),
                Category.builder().name("Bills").type("EXPENSE").user(user).build(),
                Category.builder().name("Entertainment").type("EXPENSE").user(user).build(),
                Category.builder().name("Health").type("EXPENSE").user(user).build(),
                Category.builder().name("Other").type("EXPENSE").user(user).build(),
                Category.builder().name("Salary").type("INCOME").user(user).build(),
                Category.builder().name("Freelance").type("INCOME").user(user).build(),
                Category.builder().name("Other Income").type("INCOME").user(user).build()
        );

        categoryRepository.saveAll(defaultCategories);
    }
}