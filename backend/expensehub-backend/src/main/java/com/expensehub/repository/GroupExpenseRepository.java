package com.expensehub.repository;


import com.expensehub.entity.GroupExpense;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;


import java.util.List;
import java.util.UUID;


public interface GroupExpenseRepository
        extends JpaRepository<GroupExpense, UUID> {


    List<GroupExpense> findByGroupId(UUID groupId);


    List<GroupExpense> findByGroupIdOrderByExpenseDateDesc(
            UUID groupId
    );

    @Modifying
    @Query("DELETE FROM GroupExpense e WHERE e.group.id = :groupId")
    void deleteByGroupId(@Param("groupId") UUID groupId);

    boolean existsByGroupId(UUID groupId);
}