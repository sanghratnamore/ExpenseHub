package com.expensehub.dto;


public record ChangePasswordRequest(
        String currentPassword,
        String newPassword,
        String confirmPassword
) {}