package com.expensehub.controller;

import com.expensehub.entity.*;
import com.expensehub.repository.*;
import com.expensehub.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/friends")
@RequiredArgsConstructor
public class FriendController {

    private final FriendshipRepository
            friendshipRepository;

    private final UserRepository userRepository;

    private final CurrentUser currentUser;

    @GetMapping
    public ResponseEntity<List<Map<String, Object>>>
    getFriends() {

        User user = currentUser.getUser();

        List<Friendship> friendships =
                friendshipRepository
                        .findAcceptedFriends(
                                user.getId()
                        );

        List<Map<String, Object>> friends =
                new ArrayList<>();

        for (Friendship friendship :
                friendships) {

            User friend =
                    friendship.getRequester()
                            .getId()
                            .equals(user.getId())
                            ? friendship.getReceiver()
                            : friendship.getRequester();

            friends.add(Map.of(
                    "id", friend.getId(),
                    "name", friend.getName(),
                    "email", friend.getEmail()
            ));
        }

        return ResponseEntity.ok(friends);
    }

    @PostMapping("/request")
    public ResponseEntity<String> sendRequest(
            @RequestBody Map<String, UUID> request
    ) {
        User sender = currentUser.getUser();

        User receiver =
                userRepository.findById(
                        request.get("receiverId")
                ).orElseThrow(() ->
                        new RuntimeException(
                                "User not found"
                        )
                );

        if (sender.getId()
                .equals(receiver.getId())) {
            throw new RuntimeException(
                    "You cannot add yourself"
            );
        }

        boolean alreadyExists =
                friendshipRepository
                        .existsByRequesterIdAndReceiverId(
                                sender.getId(),
                                receiver.getId()
                        );

        if (alreadyExists) {
            throw new RuntimeException(
                    "Friend request already sent"
            );
        }

        friendshipRepository.save(
                Friendship.builder()
                        .requester(sender)
                        .receiver(receiver)
                        .status(
                                FriendshipStatus.PENDING
                        )
                        .build()
        );

        return ResponseEntity.ok(
                "Friend request sent"
        );
    }

    @GetMapping("/search")
    public ResponseEntity<Map<String, Object>> searchByEmail(
            @RequestParam String email
    ) {
        User user = userRepository
                .findByEmail(email)
                .orElseThrow(() ->
                        new RuntimeException(
                                "User not found"
                        )
                );

        return ResponseEntity.ok(
                Map.of(
                        "id", user.getId(),
                        "name", user.getName(),
                        "email", user.getEmail()
                )
        );
    }

    @PostMapping(
            "/requests/{friendshipId}/accept"
    )
    public ResponseEntity<String> acceptRequest(
            @PathVariable UUID friendshipId
    ) {
        User user = currentUser.getUser();

        Friendship friendship =
                friendshipRepository
                        .findById(friendshipId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Request not found"
                                )
                        );

        if (!friendship.getReceiver()
                .getId()
                .equals(user.getId())) {
            throw new RuntimeException(
                    "You cannot accept this request"
            );
        }

        friendship.setStatus(
                FriendshipStatus.ACCEPTED
        );

        friendshipRepository.save(
                friendship
        );

        return ResponseEntity.ok(
                "Friend added"
        );
    }
}