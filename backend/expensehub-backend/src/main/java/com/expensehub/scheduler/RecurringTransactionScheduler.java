package com.expensehub.scheduler;

import com.expensehub.entity.Category;
import com.expensehub.entity.RecurringTransaction;
import com.expensehub.entity.Transaction;
import com.expensehub.repository.CategoryRepository;
import com.expensehub.repository.RecurringTransactionRepository;
import com.expensehub.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Component
@RequiredArgsConstructor
public class RecurringTransactionScheduler {

    private final RecurringTransactionRepository recurringTransactionRepository;
    private final TransactionRepository transactionRepository;
    private final CategoryRepository categoryRepository;


    @Scheduled(cron = "0 0 0 * * *")
    @Transactional
    public void generateDueTransactions() {

        LocalDate today = LocalDate.now();

        List<RecurringTransaction> dueRules =
                recurringTransactionRepository.findByNextDueDateLessThanEqualAndActiveTrue(today);

        for (RecurringTransaction recurring : dueRules) {


            System.out.println("TITLE: " + recurring.getTitle());
            System.out.println("CATEGORY ID: " + recurring.getCategoryId());
            System.out.println("NEXT DUE: " + recurring.getNextDueDate());
            System.out.println("ACTIVE: " + recurring.isActive());

            if (recurring.getCategoryId() == null) {
                System.out.println("SKIPPED: category_id is null");
                continue;
            }

            Category category = categoryRepository
                    .findById(recurring.getCategoryId())
                    .orElseThrow(() -> new RuntimeException(
                            "Category not found for recurring transaction: "
                                    + recurring.getId()
                    ));

            System.out.println("CREATING TRANSACTION FOR RULE: " + recurring.getId());

            Transaction transaction = Transaction.builder()
                    .type(recurring.getType())
                    .amount(BigDecimal.valueOf(recurring.getAmount()))
                    .description(recurring.getTitle())
                    .date(recurring.getNextDueDate())
                    .user(recurring.getUser())
                    .category(category)
                    .recurringTransaction(recurring)
                    .build();

            transactionRepository.save(transaction);

            recurring.setNextDueDate(
                    calculateNextDueDate(
                            recurring.getNextDueDate(),
                            recurring.getFrequency()
                    )
            );

            recurringTransactionRepository.save(recurring);

            System.out.println("NEW TRANSACTION CREATED FOR RULE: " + recurring.getId());
        }
    }

    private LocalDate calculateNextDueDate(LocalDate date, String frequency) {
        return switch (frequency.toUpperCase()) {
            case "DAILY" -> date.plusDays(1);
            case "WEEKLY" -> date.plusWeeks(1);
            case "MONTHLY" -> date.plusMonths(1);
            case "YEARLY" -> date.plusYears(1);
            default -> date;
        };
    }
}