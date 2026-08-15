package com.expensehub.backend.dto;

import java.util.List;
import java.util.UUID;

public class AddGroupMembersRequest {

    private List<UUID> userIds;

    public AddGroupMembersRequest() {
    }

    public List<UUID> getUserIds() {
        return userIds;
    }

    public void setUserIds(List<UUID> userIds) {
        this.userIds = userIds;
    }
}