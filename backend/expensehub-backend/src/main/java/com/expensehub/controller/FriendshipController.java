package com.expensehub.controller;

import com.expensehub.dto.FriendRequestResponse;
import com.expensehub.dto.FriendResponse;
import com.expensehub.service.FriendshipService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/friends")
@RequiredArgsConstructor
public class FriendshipController {

    private final FriendshipService friendshipService;

    @GetMapping
    public ResponseEntity<List<FriendResponse>> getFriends() {
        return ResponseEntity.ok(friendshipService.getFriends());
    }

    @GetMapping("/requests/incoming")
    public ResponseEntity<List<FriendRequestResponse>> getIncomingRequests() {
        return ResponseEntity.ok(friendshipService.getIncomingRequests());
    }

    @GetMapping("/requests/outgoing")
    public ResponseEntity<List<FriendRequestResponse>> getOutgoingRequests() {
        return ResponseEntity.ok(friendshipService.getOutgoingRequests());
    }

    @PostMapping("/requests")
    public ResponseEntity<?> sendRequest(@RequestBody Map<String, String> body) {
        friendshipService.sendRequest(body.get("email"));
        return ResponseEntity.ok(Map.of("message", "Friend request sent"));
    }

    @PostMapping("/requests/{id}/accept")
    public ResponseEntity<?> acceptRequest(@PathVariable UUID id) {
        friendshipService.acceptRequest(id);
        return ResponseEntity.ok(Map.of("message", "Friend request accepted"));
    }

    @PostMapping("/requests/{id}/reject")
    public ResponseEntity<?> rejectRequest(@PathVariable UUID id) {
        friendshipService.rejectRequest(id);
        return ResponseEntity.ok(Map.of("message", "Friend request rejected"));
    }

    @DeleteMapping("/{friendId}")
    public ResponseEntity<?> removeFriend(@PathVariable UUID friendId) {
        friendshipService.removeFriend(friendId);
        return ResponseEntity.ok(Map.of("message", "Friend removed"));
    }
}