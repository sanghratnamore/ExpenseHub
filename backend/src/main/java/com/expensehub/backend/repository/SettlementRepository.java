package com.expensehub.backend.repository;

import com.expensehub.backend.entity.Settlement;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface SettlementRepository
        extends JpaRepository<Settlement, UUID> {

    List<Settlement> findByGroupId(UUID groupId);

    List<Settlement> findByPaidById(UUID userId);

    List<Settlement> findByPaidToId(UUID userId);
}