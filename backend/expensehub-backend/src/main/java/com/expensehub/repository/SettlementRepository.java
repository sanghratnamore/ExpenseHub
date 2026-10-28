package com.expensehub.repository;

import com.expensehub.entity.Settlement;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public interface SettlementRepository extends JpaRepository<Settlement, UUID> {

    @Query("""
                SELECT s FROM Settlement s
                WHERE s.group.id = :groupId
                ORDER BY s.settledAt DESC
            """)
    List<Settlement> findByGroupId(
            @Param("groupId") UUID groupId
    );

    @Query("""
                SELECT COALESCE(SUM(s.amount), 0)
                FROM Settlement s
                WHERE s.group.id = :groupId
                AND s.paidBy.id = :userId
            """)
    BigDecimal getTotalPaidByUser(
            @Param("groupId") UUID groupId,
            @Param("userId") UUID userId
    );

    @Query("""
                SELECT COALESCE(SUM(s.amount), 0)
                FROM Settlement s
                WHERE s.group.id = :groupId
                AND s.paidTo.id = :userId
            """)
    BigDecimal getTotalReceivedByUser(
            @Param("groupId") UUID groupId,
            @Param("userId") UUID userId
    );

    @Modifying
    @Query("DELETE FROM Settlement s WHERE s.group.id = :groupId")
    void deleteByGroupId(@Param("groupId") UUID groupId);
}