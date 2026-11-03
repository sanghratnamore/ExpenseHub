package com.expensehub.scheduler;

import com.expensehub.entity.User;
import com.expensehub.repository.AppNotificationRepository;
import com.expensehub.repository.TransactionRepository;
import com.expensehub.repository.UserRepository;
import com.expensehub.service.NotificationService;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Component
@RequiredArgsConstructor
public class NotificationScheduler {

    private final NotificationService notificationService;
    private final UserRepository userRepository;
    private final AppNotificationRepository notificationRepository;
    private final TransactionRepository transactionRepository;

    @Scheduled(cron = "0 0 8 * * *")
    public void sendDailyNotifications() {
        LocalDate today = LocalDate.now();

        List<User> users = userRepository.findAll();

        for (User user : users) {
            checkRecurringTransactions(user, today);
            checkBudget(user);
        }
    }

    @Scheduled(cron = "0 0 3 * * *")
    @Transactional
    public void deleteOldReadNotifications() {
        LocalDateTime sevenDaysAgo =
                LocalDateTime.now().minusDays(7);

        notificationRepository
                .deleteByIsReadTrueAndCreatedAtBefore(sevenDaysAgo);
    }

    @Transactional
    public void checkBudget(User user) {
        if (user.getMonthlyBudget() == null ||
                user.getMonthlyBudget()
                        .compareTo(BigDecimal.ZERO) <= 0) {
            return;
        }

        LocalDate now = LocalDate.now();

        LocalDate monthStart = now.withDayOfMonth(1);
        LocalDate monthEnd = monthStart.plusMonths(1);

        BigDecimal monthlyExpense =
                transactionRepository.getTotalByTypeAndDateRange(
                        user.getId(),
                        "EXPENSE",
                        monthStart,
                        monthEnd
                );

        BigDecimal budget = user.getMonthlyBudget();

        BigDecimal usedPercentage = monthlyExpense
                .multiply(BigDecimal.valueOf(100))
                .divide(budget, 2, RoundingMode.HALF_UP);

        if (usedPercentage.compareTo(BigDecimal.valueOf(100)) >= 0) {
            notificationService.createBudgetNotificationIfNotSent(
                    user,
                    "BUDGET_EXCEEDED",
                    "Budget exceeded",
                    "You have exceeded your monthly budget."
            );

            return;
        }

        if (usedPercentage.compareTo(BigDecimal.valueOf(80)) >= 0) {
            notificationService.createBudgetNotificationIfNotSent(
                    user,
                    "BUDGET_NEAR_LIMIT",
                    "Budget warning",
                    "You have used 80% or more of your monthly budget."
            );
        }
    }

    private void checkRecurringTransactions(User user, LocalDate today) {
        // We will fill this after seeing your RecurringTransaction entity/repository
    }
}