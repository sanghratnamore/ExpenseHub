package com.expensehub.exception;

public class GroupInUseException extends RuntimeException {
    public GroupInUseException(String message) {
        super(message);
    }
}