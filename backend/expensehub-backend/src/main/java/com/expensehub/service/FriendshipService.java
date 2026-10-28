package com.expensehub.service;

import com.expensehub.dto.FriendRequestResponse;
import com.expensehub.dto.FriendResponse;
import com.expensehub.entity.Friendship;
import com.expensehub.entity.FriendshipStatus;
import com.expensehub.entity.User;
import com.expensehub.repository.FriendshipRepository;
import com.expensehub.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class FriendshipService {

    private final FriendshipRepository friendshipRepository;
    private final UserRepository userRepository;

    private User currentUser() {
        String email = SecurityContextHolder.getContext()
                .getAuthentication()
                .getName();

        return userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Current user not found"));
    }

    @Transactional(readOnly = true)
    public List<FriendResponse> getFriends() {
        User me = currentUser();

        List<FriendResponse> friends = new ArrayList<>();

        for (Friendship friendship : friendshipRepository.findAcceptedFriends(me.getId())) {

            User friend = friendship.getRequester().getId().equals(me.getId())
                    ? friendship.getReceiver()
                    : friendship.getRequester();

            friends.add(
                    FriendResponse.builder()
                            .id(friend.getId())
                            .name(friend.getName())
                            .email(friend.getEmail())
                            .build()
            );
        }

        return friends;
    }

    @Transactional(readOnly = true)
    public List<FriendRequestResponse> getIncomingRequests() {
        User me = currentUser();

        return friendshipRepository
                .findByReceiverIdAndStatus(me.getId(), FriendshipStatus.PENDING)
                .stream()
                .map(this::toRequestResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<FriendRequestResponse> getOutgoingRequests() {
        User me = currentUser();

        return friendshipRepository
                .findByRequesterIdAndStatus(me.getId(), FriendshipStatus.PENDING)
                .stream()
                .map(this::toRequestResponse)
                .toList();
    }

    @Transactional
    public void sendRequest(String email) {
        User me = currentUser();

        User receiver = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new RuntimeException("User not found")
                );

        if (me.getId().equals(receiver.getId())) {
            throw new RuntimeException(
                    "You cannot add yourself"
            );
        }

        Friendship existing =
                friendshipRepository
                        .findByRequesterIdAndReceiverId(
                                me.getId(),
                                receiver.getId()
                        )
                        .or(() -> friendshipRepository
                                .findByRequesterIdAndReceiverId(
                                        receiver.getId(),
                                        me.getId()
                                ))
                        .orElse(null);

        if (existing != null) {
            if (existing.getStatus() == FriendshipStatus.ACCEPTED) {
                throw new RuntimeException(
                        "You are already friends"
                );
            }

            if (existing.getStatus() == FriendshipStatus.PENDING) {
                throw new RuntimeException(
                        "Friend request already sent"
                );
            }

            // REJECTED: allow sending again
            existing.setRequester(me);
            existing.setReceiver(receiver);
            existing.setStatus(FriendshipStatus.PENDING);

            friendshipRepository.save(existing);
            return;
        }

        friendshipRepository.save(
                Friendship.builder()
                        .requester(me)
                        .receiver(receiver)
                        .status(FriendshipStatus.PENDING)
                        .build()
        );
    }

    @Transactional
    public void acceptRequest(UUID requestId) {
        User me = currentUser();

        Friendship friendship = friendshipRepository.findById(requestId)
                .orElseThrow(() -> new RuntimeException("Request not found"));

        if (!friendship.getReceiver().getId().equals(me.getId())) {
            throw new RuntimeException("You cannot accept this request");
        }

        friendship.setStatus(FriendshipStatus.ACCEPTED);
        friendshipRepository.save(friendship);
    }

    @Transactional
    public void rejectRequest(UUID  requestId) {
        User me = currentUser();

        Friendship friendship = friendshipRepository.findById(requestId)
                .orElseThrow(() -> new RuntimeException("Request not found"));

        if (!friendship.getReceiver().getId().equals(me.getId())) {
            throw new RuntimeException("You cannot reject this request");
        }

        friendship.setStatus(FriendshipStatus.REJECTED);
        friendshipRepository.save(friendship);
    }

    @Transactional
    public void removeFriend(UUID  friendId) {
        User me = currentUser();

        friendshipRepository.findByRequesterIdAndReceiverId(me.getId(), friendId)
                .or(() -> friendshipRepository.findByRequesterIdAndReceiverId(
                        friendId,
                        me.getId()
                ))
                .ifPresent(friendshipRepository::delete);
    }

    private FriendRequestResponse toRequestResponse(Friendship friendship) {
        User requester = friendship.getRequester();
        User receiver = friendship.getReceiver();

        return FriendRequestResponse.builder()
                .id(friendship.getId())
                .requesterId(requester.getId())
                .requesterName(requester.getName())
                .requesterEmail(requester.getEmail())
                .receiverId(receiver.getId())
                .receiverName(receiver.getName())
                .receiverEmail(receiver.getEmail())
                .status(friendship.getStatus().name())
                .build();
    }
}