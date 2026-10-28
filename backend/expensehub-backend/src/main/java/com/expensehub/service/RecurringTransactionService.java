package com.expensehub.service;


import com.expensehub.dto.RecurringTransactionRequest;
import com.expensehub.entity.RecurringTransaction;
import com.expensehub.entity.Transaction;
import com.expensehub.entity.User;
import com.expensehub.repository.RecurringTransactionRepository;
import com.expensehub.repository.TransactionRepository;
import com.expensehub.repository.UserRepository;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;


import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;


@Service
public class RecurringTransactionService {


    private final RecurringTransactionRepository
            recurringTransactionRepository;


    private final TransactionRepository
            transactionRepository;

    private final UserRepository
            userRepository;

    public RecurringTransactionService(
            RecurringTransactionRepository
                    recurringTransactionRepository,
            TransactionRepository
                    transactionRepository,
            UserRepository userRepository
    ) {
        this.recurringTransactionRepository =
                recurringTransactionRepository;


        this.transactionRepository =
                transactionRepository;


        this.userRepository = userRepository;
    }


    public RecurringTransaction
    createRecurringTransaction(
            RecurringTransactionRequest request
    ) {


        User user = getCurrentUser();


        RecurringTransaction rule =
                new RecurringTransaction();


        rule.setUser(user);
        rule.setTitle(request.getTitle());
        rule.setAmount(request.getAmount());
        rule.setType(request.getType());
        rule.setCategory(request.getCategory());
        rule.setDescription(request.getDescription());
        rule.setFrequency(request.getFrequency());
        rule.setStartDate(request.getStartDate());
        rule.setNextDueDate(request.getStartDate());
        rule.setActive(true);


        return recurringTransactionRepository
                .save(rule);
    }


    public List<RecurringTransaction>
    getRecurringTransactionsByUser() {


        User user = getCurrentUser();


        return recurringTransactionRepository
                .findByUserIdAndActiveTrue(
                        user.getId()
                );
    }



    public void deleteRecurringTransaction(
            UUID id
    ) {


        User user = getCurrentUser();


        RecurringTransaction rule =
                recurringTransactionRepository
                        .findById(id)
                        .orElseThrow();


        if (!rule.getUser().getId()
                .equals(user.getId())) {
            throw new RuntimeException(
                    "Not allowed"
            );
        }


        recurringTransactionRepository.delete(rule);
    }


    public List<RecurringTransaction>
    getDueRecurringTransactions(
            LocalDate today
    ) {


        return recurringTransactionRepository
                .findByActiveTrueAndNextDueDateLessThanEqual(
                        today
                );
    }


    @Transactional
    public void createTransactionFromRule(
            RecurringTransaction rule
    ) {


        Transaction transaction =
                new Transaction();


        transaction.setUser(rule.getUser());


        transaction.setAmount(
                BigDecimal.valueOf(
                        rule.getAmount()
                )
        );


        transaction.setType(rule.getType());


        transaction.setDate(
                rule.getNextDueDate()
        );


        transactionRepository.save(transaction);


        rule.setNextDueDate(
                calculateNextDueDate(
                        rule.getNextDueDate(),
                        rule.getFrequency()
                )
        );


        recurringTransactionRepository.save(rule);
    }


    private User getCurrentUser() {


        Authentication authentication =
                SecurityContextHolder.getContext()
                        .getAuthentication();


        Object principal =
                authentication.getPrincipal();


        if (principal instanceof User user) {
            return user;
        }


        if (principal instanceof UserDetails userDetails) {
            String email =
                    userDetails.getUsername();


            return userRepository
                    .findByEmail(email)
                    .orElseThrow(() -> new RuntimeException(
                            "User not found: " + email
                    ));
        }


        throw new RuntimeException(
                "User not authenticated"
        );
    }
    private LocalDate calculateNextDueDate(
            LocalDate current,
            String frequency
    ) {


        String value = frequency == null
                ? "MONTHLY"
                : frequency.toUpperCase();


        return switch (value) {
            case "DAILY" -> current.plusDays(1);
            case "WEEKLY" -> current.plusWeeks(1);
            case "MONTHLY" ->
                    current.plusMonths(1);
            case "YEARLY" ->
                    current.plusYears(1);
            default -> current.plusMonths(1);
        };
    }
}