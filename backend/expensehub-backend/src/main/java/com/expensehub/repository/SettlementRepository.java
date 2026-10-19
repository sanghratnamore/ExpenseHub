package com.expensehub.repository;

import com.expensehub.entity.Settlement;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.util.List;

public interface SettlementRepository extends JpaRepository<Settlement, Long> {

    List<Settlement> findByGroupId(Long groupId);

    @Query("""
        SELECT COALESCE(SUM(s.amount), 0)
        FROM Settlement s
        WHERE s.group.id = :groupId
        AND s.paidBy.id = :userId
    """)
    BigDecimal getTotalPaidByUser(
            @Param("groupId") Long groupId,
            @Param("userId") Long userId
    );

    @Query("""
        SELECT COALESCE(SUM(s.amount), 0)
        FROM Settlement s
        WHERE s.group.id = :groupId
        AND s.paidTo.id = :userId
    """)
    BigDecimal getTotalReceivedByUser(
            @Param("groupId") Long groupId,
            @Param("userId") Long userId
    );
}