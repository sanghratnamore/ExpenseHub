package com.expensehub.service;

import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private String fromEmail;

    @Value("${app.base-url}")
    private String baseUrl;

    public void sendVerificationEmail(String toEmail, String otp, String linkToken) {
        String verificationLink =
                baseUrl + "/api/auth/verify-email?token=" + linkToken;

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper =
                    new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(fromEmail);
            helper.setTo(toEmail);
            helper.setSubject("Verify your ExpenseHub account");

            String html = """
                    <div style="font-family:Arial,sans-serif;max-width:520px;margin:auto;padding:24px;">
                        <h2 style="color:#0F766E;">Welcome to ExpenseHub</h2>
                        <p>Please verify your email address to activate your account.</p>
                    
                        <p style="margin:28px 0;">
                            <a href="%s"
                               style="background:#0F766E;color:white;padding:14px 28px;
                                      text-decoration:none;border-radius:12px;font-weight:bold;">
                                Verify my email
                            </a>
                        </p>
                    
                        <p>Or enter this 6-digit code in the ExpenseHub app:</p>
                    
                        <h1 style="letter-spacing:8px;color:#0F766E;">%s</h1>
                    
                        <p style="color:#666;font-size:13px;">
                            This code and link expire in 10 minutes.
                            If you did not create an account, ignore this email.
                        </p>
                    </div>
                    """.formatted(verificationLink, otp);

            helper.setText(html, true);
            mailSender.send(message);

        } catch (Exception e) {
            throw new RuntimeException("Failed to send verification email", e);
        }
    }

    public void sendPasswordResetEmail(String toEmail, String token) {
        String resetLink =
                baseUrl + "/api/auth/reset-password?token=" + token;

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper =
                    new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(fromEmail);
            helper.setTo(toEmail);
            helper.setSubject("Reset your ExpenseHub password");

            String html = """
                    <div style="font-family:Arial,sans-serif;max-width:520px;margin:auto;padding:24px;">
                        <h2 style="color:#0F766E;">Reset your password</h2>
                        <p>Tap the button below to choose a new password.</p>
                    
                        <p style="margin:28px 0;">
                            <a href="%s"
                               style="background:#0F766E;color:white;padding:14px 28px;
                                      text-decoration:none;border-radius:12px;font-weight:bold;">
                                Reset password
                            </a>
                        </p>
                    
                        <p style="color:#666;font-size:13px;">
                            This link expires in 1 hour.
                            If you did not request this, ignore this email.
                        </p>
                    </div>
                    """.formatted(resetLink);

            helper.setText(html, true);
            mailSender.send(message);

        } catch (Exception e) {
            throw new RuntimeException("Failed to send password reset email", e);
        }
    }

    public void sendPasswordResetOtpEmail(String toEmail, String otp) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper =
                    new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(fromEmail);
            helper.setTo(toEmail);
            helper.setSubject("Your ExpenseHub password reset code");

            String html = """
                    <div style="font-family:Arial,sans-serif;max-width:520px;margin:auto;padding:24px;">
                        <h2 style="color:#0F766E;">Reset your password</h2>
                        <p>Enter this 6-digit code in the ExpenseHub app to reset your password.</p>
                    
                        <h1 style="letter-spacing:8px;color:#0F766E;">%s</h1>
                    
                        <p style="color:#666;font-size:13px;">
                            This code expires in 10 minutes.
                            If you did not request a password reset, ignore this email.
                        </p>
                    </div>
                    """.formatted(otp);

            helper.setText(html, true);
            mailSender.send(message);

        } catch (Exception e) {
            throw new RuntimeException("Failed to send password reset email", e);
        }
    }

}