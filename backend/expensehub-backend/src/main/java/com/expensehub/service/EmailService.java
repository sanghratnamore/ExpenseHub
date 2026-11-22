package com.expensehub.service;

import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private String fromEmail;

    @Value("${app.base-url}")
    private String baseUrl;

    public void sendVerificationEmail(String toEmail, String otp, String linkToken) {
        validateEmailInputs(toEmail, otp, linkToken);

        String verificationLink =
                baseUrl + "/api/auth/verify-email?token=" + linkToken;

        String subject = "Verify your ExpenseHub account";

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

        sendHtmlEmail(toEmail, subject, html, "verification email");
    }

    public void sendPasswordResetEmail(String toEmail, String token) {
        if (toEmail == null || toEmail.isBlank()) {
            throw new IllegalArgumentException("Email address is required");
        }

        if (token == null || token.isBlank()) {
            throw new IllegalArgumentException("Password reset token is required");
        }

        String resetLink =
                baseUrl + "/api/auth/reset-password?token=" + token;

        String subject = "Reset your ExpenseHub password";

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

        sendHtmlEmail(toEmail, subject, html, "password reset email");
    }

    public void sendPasswordResetOtpEmail(String toEmail, String otp) {
        validateEmailInputs(toEmail, otp, null);

        String subject = "Your ExpenseHub password reset code";

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

        sendHtmlEmail(toEmail, subject, html, "password reset OTP email");
    }

    private void sendHtmlEmail(
            String toEmail,
            String subject,
            String htmlContent,
            String emailType
    ) {
        try {
            MimeMessage message = mailSender.createMimeMessage();

            MimeMessageHelper helper =
                    new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(fromEmail);
            helper.setTo(toEmail);
            helper.setSubject(subject);
            helper.setText(htmlContent, true);

            mailSender.send(message);

            log.info("{} sent successfully to {}", emailType, toEmail);

        } catch (Exception e) {
            log.error("Failed to send {} to {}", emailType, toEmail, e);

            throw new RuntimeException(
                    "Failed to send " + emailType + ". Please try again later.",
                    e
            );
        }
    }

    private void validateEmailInputs(String toEmail, String otp, String linkToken) {
        if (toEmail == null || toEmail.isBlank()) {
            throw new IllegalArgumentException("Email address is required");
        }

        if (otp == null || otp.isBlank()) {
            throw new IllegalArgumentException("OTP is required");
        }

        if (linkToken != null && linkToken.isBlank()) {
            throw new IllegalArgumentException("Verification token cannot be blank");
        }
    }
}