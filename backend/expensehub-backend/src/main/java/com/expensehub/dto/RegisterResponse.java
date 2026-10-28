package com.expensehub.dto;

import lombok.*;

import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RegisterResponse {
    private UUID id;
    private String name;
    private String email;
    private String phone;
    private String message;
}