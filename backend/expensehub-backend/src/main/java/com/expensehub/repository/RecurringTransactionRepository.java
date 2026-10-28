package com.expensehub.repository;


import com.expensehub.entity.RecurringTransaction;


import org.springframework.data.jpa.repository.JpaRepository;


import java.time.LocalDate;
import java.util.List;
import java.util.UUID;


public interface RecurringTransactionRepository
        extends JpaRepository<RecurringTransaction, UUID> {


    List<RecurringTransaction>
    findByUserIdAndActiveTrue(UUID userId);


    List<RecurringTransaction>
    findByActiveTrueAndNextDueDateLessThanEqual(
            LocalDate date
    );
    List<RecurringTransaction>
    findByNextDueDateLessThanEqualAndActiveTrue(
            LocalDate date
    );
}