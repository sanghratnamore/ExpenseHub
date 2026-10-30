package com.expensehub.repository;

import com.expensehub.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<User, UUID> {
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);

    Optional<User> findByVerificationToken(String token);
    Optional<User> findByResetPasswordToken(String token);
}