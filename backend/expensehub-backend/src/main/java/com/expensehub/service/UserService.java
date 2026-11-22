package com.expensehub.service;

import com.expensehub.dto.ChangePasswordRequest;
import com.expensehub.dto.LoginRequest;
import com.expensehub.dto.LoginResponse;
import com.expensehub.dto.RegisterRequest;
import com.expensehub.dto.RegisterResponse;
import com.expensehub.entity.User;
import com.expensehub.repository.UserRepository;
import com.expensehub.security.JwtService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class UserService {

    private static final int MAX_OTP_ATTEMPTS = 5;
    private static final long OTP_RESEND_COOLDOWN_SECONDS = 90;

    private final UserRepository userRepository;
    private final JwtService jwtService;
    private final PasswordEncoder passwordEncoder;
    private final CategoryService categoryService;
    private final EmailService emailService;

    @Transactional
    public RegisterResponse registerUser(RegisterRequest request) {

        if (request.getName() == null || request.getName().isBlank()) {
            throw new RuntimeException("Name is required");
        }

        if (request.getEmail() == null || request.getEmail().isBlank()) {
            throw new RuntimeException("Email is required");
        }

        if (request.getPassword() == null || request.getPassword().length() < 6) {
            throw new RuntimeException("Password must be at least 6 characters");
        }

        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email is already registered");
        }

        User user = User.builder()
                .name(request.getName())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .phone(request.getPhone())
                .emailVerified(false)
                .build();

        User savedUser = userRepository.save(user);

        categoryService.createDefaultCategories(savedUser);

        sendVerificationEmail(savedUser);

        return RegisterResponse.builder()
                .id(savedUser.getId())
                .name(savedUser.getName())
                .email(savedUser.getEmail())
                .phone(savedUser.getPhone())
                .message("User registered successfully. Please verify your email.")
                .build();
    }

    public LoginResponse loginUser(LoginRequest request) {

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Email is not registered"));

        if (!user.isEmailVerified()) {
            throw new RuntimeException("Please verify your email before logging in");
        }

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

    @Transactional
    public void updateUserName(String email, String newName) {

        if (newName == null || newName.isBlank()) {
            throw new RuntimeException("Name is required");
        }

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        user.setName(newName);
        userRepository.save(user);
    }

    @Transactional
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
            throw new RuntimeException("New password must be at least 6 characters");
        }

        if (!request.newPassword().equals(request.confirmPassword())) {
            throw new RuntimeException("New passwords do not match");
        }

        user.setPassword(passwordEncoder.encode(request.newPassword()));
        userRepository.save(user);
    }

    @Transactional
    public void sendVerificationEmail(User user) {

        String otp = generateOtp();
        String linkToken = UUID.randomUUID().toString();

        user.setOtpCode(otp);
        user.setOtpExpiry(LocalDateTime.now().plusMinutes(10));

        user.setVerificationToken(linkToken);
        user.setVerificationTokenExpiry(LocalDateTime.now().plusMinutes(10));

        user.setOtpAttempts(0);
        user.setLastOtpSentAt(LocalDateTime.now());

        userRepository.save(user);

        try {
            emailService.sendVerificationEmail(
                    user.getEmail(),
                    otp,
                    linkToken
            );
        } catch (Exception e) {
            log.error(
                    "Verification email could not be sent to {}",
                    user.getEmail(),
                    e
            );
        }
    }

    @Transactional
    public void verifyEmail(String token) {

        if (token == null || token.isBlank()) {
            throw new RuntimeException("Verification token is required");
        }

        User user = userRepository.findByVerificationToken(token)
                .orElseThrow(() -> new RuntimeException("Invalid verification link"));

        if (user.getVerificationTokenExpiry() == null ||
                user.getVerificationTokenExpiry().isBefore(LocalDateTime.now())) {
            throw new RuntimeException("Verification link has expired");
        }

        user.setEmailVerified(true);
        user.setVerificationToken(null);
        user.setVerificationTokenExpiry(null);
        user.setOtpCode(null);
        user.setOtpExpiry(null);
        user.setOtpAttempts(0);

        userRepository.save(user);
    }

    @Transactional
    public void resendVerificationEmail(String email) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (user.isEmailVerified()) {
            throw new RuntimeException("Email is already verified");
        }

        enforceResendCooldown(user);

        sendVerificationEmail(user);
    }

    @Transactional
    public LoginResponse verifyOtpAndLogin(String email, String otp) {

        if (email == null || email.isBlank()) {
            throw new RuntimeException("Email is required");
        }

        if (otp == null || otp.isBlank()) {
            throw new RuntimeException("OTP is required");
        }

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (user.isEmailVerified()) {
            throw new RuntimeException("Email is already verified");
        }

        if (user.getOtpAttempts() >= MAX_OTP_ATTEMPTS) {
            throw new RuntimeException(
                    "Too many incorrect attempts. Please request a new OTP."
            );
        }

        if (user.getOtpExpiry() == null ||
                user.getOtpExpiry().isBefore(LocalDateTime.now())) {
            throw new RuntimeException("OTP has expired. Please request a new OTP.");
        }

        if (user.getOtpCode() == null ||
                !user.getOtpCode().equals(otp)) {

            user.setOtpAttempts(user.getOtpAttempts() + 1);
            userRepository.save(user);

            int remaining = MAX_OTP_ATTEMPTS - user.getOtpAttempts();

            if (remaining <= 0) {
                throw new RuntimeException(
                        "Too many incorrect attempts. Please request a new OTP."
                );
            }

            throw new RuntimeException(
                    "Invalid OTP. " + remaining + " attempt(s) remaining."
            );
        }

        user.setEmailVerified(true);
        user.setOtpCode(null);
        user.setOtpExpiry(null);
        user.setOtpAttempts(0);
        user.setVerificationToken(null);
        user.setVerificationTokenExpiry(null);

        userRepository.save(user);

        String token = jwtService.generateToken(user.getEmail());

        return LoginResponse.builder()
                .token(token)
                .id(user.getId())
                .name(user.getName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .message("Email verified and login successful")
                .build();
    }

    @Transactional
    public void resendOtp(String email) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (user.isEmailVerified()) {
            throw new RuntimeException("Email is already verified");
        }

        enforceResendCooldown(user);

        sendVerificationEmail(user);
    }

    @Transactional
    public void forgotPassword(String email) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        String otp = generateOtp();

        user.setResetPasswordToken(otp);
        user.setResetPasswordTokenExpiry(LocalDateTime.now().plusMinutes(10));

        userRepository.save(user);

        emailService.sendPasswordResetOtpEmail(user.getEmail(), otp);
    }

    @Transactional
    public void resetPassword(String email, String otp, String newPassword) {

        if (otp == null || otp.isBlank()) {
            throw new RuntimeException("OTP is required");
        }

        if (newPassword == null || newPassword.length() < 6) {
            throw new RuntimeException("New password must be at least 6 characters");
        }

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (user.getResetPasswordToken() == null ||
                !user.getResetPasswordToken().equals(otp)) {
            throw new RuntimeException("Invalid OTP");
        }

        if (user.getResetPasswordTokenExpiry() == null ||
                user.getResetPasswordTokenExpiry().isBefore(LocalDateTime.now())) {
            throw new RuntimeException("OTP has expired");
        }

        user.setPassword(passwordEncoder.encode(newPassword));
        user.setResetPasswordToken(null);
        user.setResetPasswordTokenExpiry(null);

        userRepository.save(user);
    }

    public BigDecimal getMonthlyBudget(String email) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return user.getMonthlyBudget() == null
                ? BigDecimal.ZERO
                : user.getMonthlyBudget();
    }

    @Transactional
    public void updateMonthlyBudget(String email, BigDecimal budget) {

        if (budget == null || budget.compareTo(BigDecimal.ZERO) < 0) {
            throw new RuntimeException("Invalid budget amount");
        }

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        user.setMonthlyBudget(budget);
        userRepository.save(user);
    }

    private void enforceResendCooldown(User user) {

        LocalDateTime lastSent = user.getLastOtpSentAt();

        if (lastSent == null) {
            return;
        }

        LocalDateTime allowedAt = lastSent.plusSeconds(OTP_RESEND_COOLDOWN_SECONDS);

        if (LocalDateTime.now().isBefore(allowedAt)) {
            long secondsLeft = Duration
                    .between(LocalDateTime.now(), allowedAt)
                    .getSeconds() + 1;

            throw new RuntimeException(
                    "Please wait " + secondsLeft
                            + " seconds before requesting a new OTP"
            );
        }
    }

    private String generateOtp() {
        return String.format(
                "%06d",
                new SecureRandom().nextInt(1_000_000)
        );
    }
}