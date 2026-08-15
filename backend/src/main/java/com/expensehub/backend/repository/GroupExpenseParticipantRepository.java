package com.expensehub.backend.repository;

import com.expensehub.backend.entity.GroupExpense;
import com.expensehub.backend.entity.GroupExpenseParticipant;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface GroupExpenseParticipantRepository
        extends JpaRepository<GroupExpenseParticipant, UUID> {

    List<GroupExpenseParticipant> findByGroupExpense(
            GroupExpense groupExpense
    );

    List<GroupExpenseParticipant> findByGroupExpenseId(
            UUID groupExpenseId
    );
}