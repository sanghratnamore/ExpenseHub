package com.expensehub.dto;


import lombok.Builder;
import lombok.Getter;


import java.util.List;
import java.util.UUID;


@Getter
@Builder
public class GroupResponse {


    private UUID id;
    private String name;
    private String description;
    private List<MemberResponse> members;
    private String inviteCode;


    @Getter
    @Builder
    public static class MemberResponse {
        private UUID id;
        private String name;
        private String email;
        private String role;
    }
}