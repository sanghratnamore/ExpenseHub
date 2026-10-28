package com.expensehub.dto;

import lombok.Data;

import java.util.List;
import java.util.UUID;

@Data
public class AddMembersRequest {
    private List<UUID> memberIds;
}