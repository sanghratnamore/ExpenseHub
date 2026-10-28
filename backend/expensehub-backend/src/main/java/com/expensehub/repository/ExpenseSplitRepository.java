package com.expensehub.repository;


import com.expensehub.entity.ExpenseSplit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;


import java.util.List;
import java.util.UUID;


public interface ExpenseSplitRepository
        extends JpaRepository<ExpenseSplit, UUID> {


    List<ExpenseSplit> findByGroupExpenseGroupId(
            UUID groupId
    );


    List<ExpenseSplit> findByGroupExpenseId(
            UUID groupExpenseId
    );


    @Transactional
    void deleteByGroupExpenseId(UUID groupExpenseId);

    @Modifying
    @Query("DELETE FROM ExpenseSplit s WHERE s.groupExpense.group.id = :groupId")
    void deleteByGroupId(@Param("groupId") UUID groupId);
}