package com.expensehub.service;

import com.expensehub.dto.DashboardResponse;
import com.expensehub.dto.GroupBalanceResponse;
import com.expensehub.dto.SettlementResponse;
import com.expensehub.entity.ExpenseSplit;
import com.expensehub.entity.GroupEntity;
import com.expensehub.entity.GroupExpense;
import com.expensehub.entity.User;
import com.expensehub.repository.ExpenseSplitRepository;
import com.expensehub.repository.GroupExpenseRepository;
import com.expensehub.repository.GroupRepository;
import com.expensehub.repository.SettlementRepository;
import com.expensehub.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.PriorityQueue;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ExpenseCalculationEngine {

    private final TransactionRepository transactionRepository;
    private final GroupRepository groupRepository;
    private final GroupExpenseRepository groupExpenseRepository;
    private final ExpenseSplitRepository expenseSplitRepository;
    private final SettlementRepository settlementRepository;

    public DashboardResponse calculateMonthlyDashboard(
            UUID userId,
            int year,
            int month
    ) {
        YearMonth yearMonth = YearMonth.of(year, month);

        LocalDate startDate = yearMonth.atDay(1);
        LocalDate endDate = yearMonth.atEndOfMonth();

        BigDecimal totalIncome =
                transactionRepository.getTotalByTypeAndDateRange(
                        userId,
                        "INCOME",
                        startDate,
                        endDate
                );

        BigDecimal totalExpense =
                transactionRepository.getTotalByTypeAndDateRange(
                        userId,
                        "EXPENSE",
                        startDate,
                        endDate
                );

        BigDecimal savings =
                totalIncome.subtract(totalExpense);

        List<DashboardResponse.CategorySummary> categorySummaries =
                calculateCategoryTotals(
                        userId,
                        startDate,
                        endDate
                );

        return DashboardResponse.builder()
                .totalIncome(totalIncome)
                .totalExpense(totalExpense)
                .savings(savings)
                .categorySummary(categorySummaries)
                .build();
    }

    public List<DashboardResponse.CategorySummary> calculateCategoryTotals(
            UUID userId,
            LocalDate startDate,
            LocalDate endDate
    ) {
        List<Object[]> rows =
                transactionRepository.getCategoryWiseExpense(
                        userId,
                        startDate,
                        endDate
                );

        List<DashboardResponse.CategorySummary> summaries =
                new ArrayList<>();

        for (Object[] row : rows) {
            String categoryName = (String) row[0];
            BigDecimal totalAmount =
                    new BigDecimal(row[1].toString());

            summaries.add(
                    DashboardResponse.CategorySummary.builder()
                            .categoryName(categoryName)
                            .totalAmount(totalAmount)
                            .build()
            );
        }

        return summaries;
    }

    public BigDecimal calculateEqualShare(
            BigDecimal totalAmount,
            int memberCount
    ) {
        if (memberCount <= 0) {
            throw new IllegalArgumentException(
                    "At least one member is required"
            );
        }

        return totalAmount.divide(
                BigDecimal.valueOf(memberCount),
                2,
                RoundingMode.HALF_UP
        );
    }

    public List<GroupBalanceResponse> calculateGroupBalances(
            UUID groupId
    ) {
        GroupEntity group = groupRepository.findById(groupId)
                .orElseThrow(() ->
                        new RuntimeException("Group not found"));

        List<GroupExpense> expenses =
                groupExpenseRepository.findByGroupId(groupId);

        List<ExpenseSplit> splits =
                expenseSplitRepository.findByGroupExpenseGroupId(groupId);

        List<GroupBalanceResponse> balances =
                new ArrayList<>();

        for (User member : group.getMembers()) {
            BigDecimal totalPaid = BigDecimal.ZERO;
            BigDecimal totalShare = BigDecimal.ZERO;

            for (GroupExpense expense : expenses) {
                User paidBy = expense.getPaidBy();

                if (paidBy != null
                        && paidBy.getId().equals(member.getId())) {
                    totalPaid = totalPaid.add(
                            nullSafe(expense.getAmount())
                    );
                }
            }

            for (ExpenseSplit split : splits) {
                User splitUser = split.getUser();

                if (splitUser != null
                        && splitUser.getId().equals(member.getId())) {
                    totalShare = totalShare.add(
                            nullSafe(split.getShareAmount())
                    );
                }
            }

            BigDecimal settlementPaid = nullSafe(
                    settlementRepository.getTotalPaidByUser(
                            groupId,
                            member.getId()
                    )
            );

            BigDecimal settlementReceived = nullSafe(
                    settlementRepository.getTotalReceivedByUser(
                            groupId,
                            member.getId()
                    )
            );

            BigDecimal balance = totalPaid
                    .subtract(totalShare)
                    .add(settlementPaid)
                    .subtract(settlementReceived);

            balances.add(
                    buildBalanceResponse(
                            member,
                            totalPaid,
                            totalShare,
                            balance
                    )
            );
        }

        return balances;
    }

    public List<SettlementResponse> calculateSimplifiedSettlements(
            UUID groupId
    ) {
        List<GroupBalanceResponse> balances =
                calculateGroupBalances(groupId);

        PriorityQueue<GroupBalanceResponse> creditors =
                new PriorityQueue<>(
                        Comparator.comparing(
                                GroupBalanceResponse::getBalance
                        ).reversed()
                );

        PriorityQueue<GroupBalanceResponse> debtors =
                new PriorityQueue<>(
                        Comparator.comparing(
                                GroupBalanceResponse::getBalance
                        )
                );

        for (GroupBalanceResponse balance : balances) {
            if (balance.getBalance() == null) {
                continue;
            }

            if (balance.getBalance()
                    .compareTo(BigDecimal.ZERO) > 0) {
                creditors.add(balance);
            } else if (balance.getBalance()
                    .compareTo(BigDecimal.ZERO) < 0) {
                debtors.add(balance);
            }
        }

        List<SettlementResponse> suggestions =
                new ArrayList<>();

        while (!creditors.isEmpty() && !debtors.isEmpty()) {
            GroupBalanceResponse creditor =
                    creditors.poll();
            GroupBalanceResponse debtor =
                    debtors.poll();

            BigDecimal payment = creditor.getBalance()
                    .min(debtor.getBalance().abs());

            suggestions.add(
                    SettlementResponse.builder()
                            .groupId(groupId)
                            .paidById(debtor.getUserId())
                            .paidByName(debtor.getUserName())
                            .paidToId(creditor.getUserId())
                            .paidToName(creditor.getUserName())
                            .amount(payment)
                            .message("Suggested settlement")
                            .build()
            );

            BigDecimal creditorRemaining =
                    creditor.getBalance().subtract(payment);

            BigDecimal debtorRemaining =
                    debtor.getBalance().add(payment);

            if (creditorRemaining
                    .compareTo(BigDecimal.ZERO) > 0) {
                creditor.setBalance(creditorRemaining);
                creditors.add(creditor);
            }

            if (debtorRemaining
                    .compareTo(BigDecimal.ZERO) < 0) {
                debtor.setBalance(debtorRemaining);
                debtors.add(debtor);
            }
        }

        return suggestions;
    }

    private BigDecimal nullSafe(BigDecimal value) {
        return value == null ? BigDecimal.ZERO : value;
    }

    private GroupBalanceResponse buildBalanceResponse(
            User member,
            BigDecimal totalPaid,
            BigDecimal totalShare,
            BigDecimal balance
    ) {
        String status;

        if (balance.compareTo(BigDecimal.ZERO) > 0) {
            status = "SHOULD_RECEIVE";
        } else if (balance.compareTo(BigDecimal.ZERO) < 0) {
            status = "OWES";
        } else {
            status = "SETTLED";
        }

        return GroupBalanceResponse.builder()
                .userId(member.getId())
                .userName(member.getName())
                .totalPaid(totalPaid)
                .totalShare(totalShare)
                .balance(balance)
                .status(status)
                .build();
    }
}