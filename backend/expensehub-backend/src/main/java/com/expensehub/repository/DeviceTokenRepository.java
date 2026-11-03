package com.expensehub.repository;

import com.expensehub.entity.DeviceToken;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface DeviceTokenRepository
        extends JpaRepository<DeviceToken, Long> {

    List<DeviceToken> findByUserId(String userId);

    Optional<DeviceToken> findByDeviceToken(String deviceToken);
}