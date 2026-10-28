package com.expensehub.dto;

import lombok.*;

import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FriendRequestResponse {
    private UUID id;
    private UUID  requesterId;
    private String requesterName;
    private String requesterEmail;
    private UUID  receiverId;
    private String receiverName;
    private String receiverEmail;
    private String status;
}