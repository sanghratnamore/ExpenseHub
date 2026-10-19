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

import java.util.List;

@Service
@RequiredArgsConstructor
public class TransactionService {

    private final TransactionRepository transactionRepository;
    private final CategoryRepository categoryRepository;
    private final CurrentUser currentUser;

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

        return transactionRepository.save(transaction);
    }

    public List<Transaction> getTransactionsByUser() {
        User user = currentUser.getUser();
        return transactionRepository.findByUserIdOrderByDateDesc(user.getId());
    }

    @Transactional
    public Transaction updateTransaction(Long transactionId, TransactionRequest request) {

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
    public void deleteTransaction(Long transactionId) {

        User user = currentUser.getUser();

        Transaction transaction = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new RuntimeException("Transaction not found"));

        if (!transaction.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("You cannot delete another user's transaction");
        }

        transactionRepository.delete(transaction);
    }
}