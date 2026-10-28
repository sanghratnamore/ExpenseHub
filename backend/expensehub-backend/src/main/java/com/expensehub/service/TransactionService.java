package com.expensehub.service;

import com.expensehub.dto.TransactionRequest;
import com.expensehub.entity.Category;
import com.expensehub.entity.Transaction;
import com.expensehub.entity.User;
import com.expensehub.repository.CategoryRepository;
import com.expensehub.repository.TransactionRepository;
import com.expensehub.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.expensehub.entity.RecurringTransaction;
import com.expensehub.repository.RecurringTransactionRepository;

import java.util.List;
import java.time.LocalDate;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TransactionService {

    private final TransactionRepository transactionRepository;
    private final CategoryRepository categoryRepository;
    private final CurrentUser currentUser;
    private final RecurringTransactionRepository recurringTransactionRepository;

    @Transactional
    public Transaction createTransaction(TransactionRequest request) {

        User user = currentUser.getUser();


        Category category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new RuntimeException("Category not found"));

        if (!category.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("You cannot use another user's category");
        }

        Transaction transaction = Transaction.builder()
                .type(request.getType())
                .amount(request.getAmount())
                .description(request.getDescription())
                .date(request.getDate())
                .user(user)
                .category(category)
                .build();

        Transaction savedTransaction =
                transactionRepository.save(transaction);

        if (Boolean.TRUE.equals(request.getIsRecurring())) {

            RecurringTransaction recurring =
                    new RecurringTransaction();

            recurring.setUser(user);
            recurring.setCategoryId(category.getId());
            recurring.setTitle(request.getDescription());
            recurring.setAmount(request.getAmount().doubleValue());
            recurring.setType(request.getType());
            recurring.setCategory(category.getName());
            recurring.setDescription(request.getDescription());
            recurring.setFrequency(request.getRecurringFrequency());
            recurring.setStartDate(request.getDate());
            recurring.setNextDueDate(calculateNextDueDate(
                    request.getDate(),
                    request.getRecurringFrequency()
            ));
            recurring.setActive(true);

            RecurringTransaction savedRecurring =
                    recurringTransactionRepository.save(recurring);

            savedTransaction.setRecurringTransaction(savedRecurring);

            savedTransaction = transactionRepository.save(savedTransaction);
        }

        return mapRecurringDetails(savedTransaction);
    }

    private LocalDate calculateNextDueDate(
            LocalDate startDate,
            String frequency
    ) {
        if (frequency == null) {
            return startDate;
        }

        return switch (frequency.toUpperCase()) {
            case "DAILY" -> startDate.plusDays(1);
            case "WEEKLY" -> startDate.plusWeeks(1);
            case "MONTHLY" -> startDate.plusMonths(1);
            case "YEARLY" -> startDate.plusYears(1);
            default -> startDate;
        };
    }

    private Transaction mapRecurringDetails(Transaction transaction) {

        RecurringTransaction recurring =
                transaction.getRecurringTransaction();

        if (recurring != null) {
            transaction.setIsRecurring(true);
            transaction.setRecurringFrequency(recurring.getFrequency());
            transaction.setRecurringStartDate(recurring.getStartDate());
            transaction.setNextDueDate(recurring.getNextDueDate());
        } else {
            transaction.setIsRecurring(false);
        }

        return transaction;
    }


    public List<Transaction> getTransactionsByUser() {
        User user = currentUser.getUser();

        List<Transaction> transactions =
                transactionRepository.findByUserIdOrderByDateDesc(user.getId());

        return transactions.stream()
                .map(this::mapRecurringDetails)
                .toList();
    }

    @Transactional
    public Transaction updateTransaction(UUID transactionId, TransactionRequest request) {

        User user = currentUser.getUser();

        Transaction transaction = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new RuntimeException("Transaction not found"));

        if (!transaction.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("You cannot update another user's transaction");
        }

        Category category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new RuntimeException("Category not found"));

        if (!category.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("You cannot use another user's category");
        }

        transaction.setType(request.getType());
        transaction.setAmount(request.getAmount());
        transaction.setDescription(request.getDescription());
        transaction.setDate(request.getDate());
        transaction.setCategory(category);

        return transactionRepository.save(transaction);
    }

    @Transactional
    public void deleteTransaction(UUID transactionId) {

        User user = currentUser.getUser();

        Transaction transaction = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new RuntimeException("Transaction not found"));

        if (!transaction.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("You cannot delete another user's transaction");
        }

        transactionRepository.delete(transaction);
    }
}