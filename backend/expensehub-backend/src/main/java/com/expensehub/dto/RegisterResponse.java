package com.expensehub.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RegisterResponse {
    private Long id;
    private String name;
    private String email;
    private String phone;
    private String message;
}