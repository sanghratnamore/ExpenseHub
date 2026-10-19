package com.expensehub.service;

import com.expensehub.dto.*;
import com.expensehub.entity.*;
import com.expensehub.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

import com.expensehub.dto.SettlementRequest;
import com.expensehub.dto.SettlementResponse;
import com.expensehub.entity.Settlement;

@Service
@RequiredArgsConstructor
public class GroupService {

    private final GroupRepository groupRepository;
    private final UserRepository userRepository;
    private final GroupExpenseRepository groupExpenseRepository;
    private final ExpenseSplitRepository expenseSplitRepository;
    private final SettlementRepository settlementRepository;

    public GroupEntity createGroup(CreateGroupRequest request) {

        User creator = userRepository.findById(request.getCreatedBy())
                .orElseThrow(() -> new RuntimeException("Creator user not found"));

        GroupEntity group = GroupEntity.builder()
                .name(request.getName())
                .description(request.getDescription())
                .createdDate(LocalDate.now())
                .createdBy(creator)
                .build();

        group.getMembers().add(creator);

        if (request.getMemberIds() != null) {
            for (Long memberId : request.getMemberIds()) {
                boolean alreadyAdded = group.getMembers()
                        .stream()
                        .anyMatch(member -> member.getId().equals(memberId));

                if (!alreadyAdded) {
                    User member = userRepository.findById(memberId)
                            .orElseThrow(() -> new RuntimeException("Member not found: " + memberId));

                    group.getMembers().add(member);
                }
            }
        }

        return groupRepository.save(group);
    }

    public GroupExpense addGroupExpense(GroupExpenseRequest request) {

        GroupEntity group = groupRepository.findById(request.getGroupId())
                .orElseThrow(() -> new RuntimeException("Group not found"));

        User paidBy = userRepository.findById(request.getPaidBy())
                .orElseThrow(() -> new RuntimeException("Paying user not found"));

        GroupExpense expense = GroupExpense.builder()
                .description(request.getDescription())
                .amount(request.getAmount())
                .expenseDate(request.getExpenseDate())
                .group(group)
                .paidBy(paidBy)
                .build();

        GroupExpense savedExpense = groupExpenseRepository.save(expense);

        int memberCount = request.getMemberIds().size();

        BigDecimal shareAmount = request.getAmount()
                .divide(BigDecimal.valueOf(memberCount), 2, RoundingMode.HALF_UP);

        for (Long memberId : request.getMemberIds()) {
            User member = userRepository.findById(memberId)
                    .orElseThrow(() -> new RuntimeException("Member not found: " + memberId));

            ExpenseSplit split = ExpenseSplit.builder()
                    .groupExpense(savedExpense)
                    .user(member)
                    .shareAmount(shareAmount)
                    .build();

            expenseSplitRepository.save(split);
        }

        return savedExpense;
    }

    public List<GroupBalanceResponse> getGroupBalances(Long groupId) {

        GroupEntity group = groupRepository.findById(groupId)
                .orElseThrow(() -> new RuntimeException("Group not found"));

        List<GroupExpense> expenses = groupExpenseRepository.findByGroupId(groupId);
        List<ExpenseSplit> splits = expenseSplitRepository.findByGroupExpenseGroupId(groupId);

        List<GroupBalanceResponse> balances = new ArrayList<>();

        for (User member : group.getMembers()) {

            BigDecimal totalPaid = BigDecimal.ZERO;
            BigDecimal totalShare = BigDecimal.ZERO;

            for (GroupExpense expense : expenses) {
                if (expense.getPaidBy().getId().equals(member.getId())) {
                    totalPaid = totalPaid.add(expense.getAmount());
                }
            }

            for (ExpenseSplit split : splits) {
                if (split.getUser().getId().equals(member.getId())) {
                    totalShare = totalShare.add(split.getShareAmount());
                }
            }

            BigDecimal settlementPaid = settlementRepository.getTotalPaidByUser(
                    groupId, member.getId()
            );

            BigDecimal settlementReceived = settlementRepository.getTotalReceivedByUser(
                    groupId, member.getId()
            );

            BigDecimal balance = totalPaid
                    .subtract(totalShare)
                    .add(settlementPaid)
                    .subtract(settlementReceived);

            String status;
            if (balance.compareTo(BigDecimal.ZERO) > 0) {
                status = "SHOULD_RECEIVE";
            } else if (balance.compareTo(BigDecimal.ZERO) < 0) {
                status = "OWES";
            } else {
                status = "SETTLED";
            }

            balances.add(
                    GroupBalanceResponse.builder()
                            .userId(member.getId())
                            .userName(member.getName())
                            .totalPaid(totalPaid)
                            .totalShare(totalShare)
                            .balance(balance)
                            .status(status)
                            .build()
            );
        }

        return balances;
    }

    public SettlementResponse settleUp(SettlementRequest request) {

        GroupEntity group = groupRepository.findById(request.getGroupId())
                .orElseThrow(() -> new RuntimeException("Group not found"));

        User paidBy = userRepository.findById(request.getPaidBy())
                .orElseThrow(() -> new RuntimeException("Paying user not found"));

        User paidTo = userRepository.findById(request.getPaidTo())
                .orElseThrow(() -> new RuntimeException("Receiving user not found"));

        if (paidBy.getId().equals(paidTo.getId())) {
            throw new RuntimeException("A user cannot settle up with themselves");
        }

        Settlement settlement = Settlement.builder()
                .group(group)
                .paidBy(paidBy)
                .paidTo(paidTo)
                .amount(request.getAmount())
                .settlementDate(request.getSettlementDate())
                .build();

        Settlement savedSettlement = settlementRepository.save(settlement);

        return SettlementResponse.builder()
                .id(savedSettlement.getId())
                .groupId(group.getId())
                .paidByName(paidBy.getName())
                .paidToName(paidTo.getName())
                .amount(savedSettlement.getAmount())
                .settlementDate(savedSettlement.getSettlementDate())
                .message("Settlement recorded successfully")
                .build();
    }

    public List<SettlementResponse> getSettlements(Long groupId) {

        List<Settlement> settlements = settlementRepository.findByGroupId(groupId);

        List<SettlementResponse> responses = new ArrayList<>();

        for (Settlement settlement : settlements) {
            responses.add(
                    SettlementResponse.builder()
                            .id(settlement.getId())
                            .groupId(settlement.getGroup().getId())
                            .paidByName(settlement.getPaidBy().getName())
                            .paidToName(settlement.getPaidTo().getName())
                            .amount(settlement.getAmount())
                            .settlementDate(settlement.getSettlementDate())
                            .message("Settlement record")
                            .build()
            );
        }

        return responses;
    }
}