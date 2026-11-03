package com.expensehub.scheduler;

import com.expensehub.entity.AppNotification;
import com.expensehub.entity.Category;
import com.expensehub.entity.RecurringTransaction;
import com.expensehub.entity.Transaction;
import com.expensehub.repository.AppNotificationRepository;
import com.expensehub.repository.CategoryRepository;
import com.expensehub.repository.RecurringTransactionRepository;
import com.expensehub.repository.TransactionRepository;
import com.expensehub.service.NotificationService;
import com.expensehub.service.PushNotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Component
@RequiredArgsConstructor
public class RecurringTransactionScheduler {

    private final RecurringTransactionRepository recurringTransactionRepository;
    private final TransactionRepository transactionRepository;
    private final CategoryRepository categoryRepository;
    private final NotificationService notificationService;
    private final PushNotificationService pushNotificationService;
    private final AppNotificationRepository notificationRepository;

    @Scheduled(cron = "0 0 0 * * *")
    @Transactional
    public void generateDueTransactions() {

        LocalDate today = LocalDate.now();

        List<RecurringTransaction> dueRules =
                recurringTransactionRepository
                        .findByNextDueDateLessThanEqualAndActiveTrue(today);

        for (RecurringTransaction recurring : dueRules) {

            if (recurring.getCategoryId() == null) {
                continue;
            }

            Category category = categoryRepository
                    .findById(recurring.getCategoryId())
                    .orElse(null);

            if (category == null) {
                continue;
            }

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

            sendRecurringCreatedNotification(recurring);
        }
    }

    private void sendRecurringCreatedNotification(
            RecurringTransaction recurring
    ) {
        LocalDate today = LocalDate.now();

        String type = "RECURRING_TRANSACTION_CREATED";

        String title = recurring.getType()
                .equalsIgnoreCase("INCOME")
                ? "Recurring income added"
                : "Recurring expense added";

        String message = recurring.getTitle()
                + " (₹"
                + recurring.getAmount()
                + ") was added automatically for "
                + recurring.getNextDueDate()
                + ".";

        LocalDateTime dayStart = today.atStartOfDay();
        LocalDateTime dayEnd = dayStart.plusDays(1);

        boolean alreadySent = notificationRepository
                .existsByUserAndTypeAndCreatedAtBetween(
                        recurring.getUser(),
                        type,
                        dayStart,
                        dayEnd
                );

        if (alreadySent) return;

        notificationService.createNotification(
                recurring.getUser(),
                type,
                title,
                message,
                null,
                null,
                null
        );

        pushNotificationService.sendToUsers(
                List.of(recurring.getUser().getId().toString()),
                title,
                message,
                null,
                null,
                type
        );
    }

    private LocalDate calculateNextDueDate(
            LocalDate date,
            String frequency
    ) {
        return switch (frequency.toUpperCase()) {
            case "DAILY" -> date.plusDays(1);
            case "WEEKLY" -> date.plusWeeks(1);
            case "MONTHLY" -> date.plusMonths(1);
            case "YEARLY" -> date.plusYears(1);
            default -> date;
        };
    }

    @Scheduled(cron = "0 0 8 * * *")
    @Transactional
    public void sendDueReminders() {
        LocalDate today = LocalDate.now();
        LocalDate tomorrow = today.plusDays(1);

        List<RecurringTransaction> upcomingRules =
                recurringTransactionRepository
                        .findByActiveTrueAndNextDueDateBetween(
                                today,
                                tomorrow
                        );

        for (RecurringTransaction recurring : upcomingRules) {
            sendDueReminder(recurring);
        }
    }

    private void sendDueReminder(
            RecurringTransaction recurring
    ) {
        LocalDate today = LocalDate.now();

        String when = recurring.getNextDueDate().equals(today)
                ? "today"
                : "tomorrow";

        String type = "RECURRING_TRANSACTION_DUE";

        String title = "Recurring payment due";

        String message = "Your "
                + recurring.getFrequency().toLowerCase()
                + " "
                + recurring.getTitle()
                + " payment of ₹"
                + recurring.getAmount()
                + " is due "
                + when
                + ".";

        LocalDateTime dayStart = today.atStartOfDay();
        LocalDateTime dayEnd = dayStart.plusDays(1);

        boolean alreadySent = notificationRepository
                .existsByUserAndTypeAndCreatedAtBetween(
                        recurring.getUser(),
                        type,
                        dayStart,
                        dayEnd
                );

        if (alreadySent) return;

        notificationService.createNotification(
                recurring.getUser(),
                type,
                title,
                message,
                null,
                null,
                null
        );

        pushNotificationService.sendToUsers(
                List.of(recurring.getUser().getId().toString()),
                title,
                message,
                null,
                null,
                type
        );
    }
}