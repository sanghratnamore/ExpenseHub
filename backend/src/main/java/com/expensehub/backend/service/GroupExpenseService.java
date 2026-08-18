package com.expensehub.backend.service;

import com.expensehub.backend.dto.CreateGroupExpenseRequest;
import com.expensehub.backend.dto.GroupExpenseResponse;
import com.expensehub.backend.entity.Group;
import com.expensehub.backend.entity.GroupExpense;
import com.expensehub.backend.entity.GroupExpenseParticipant;
import com.expensehub.backend.entity.User;
import com.expensehub.backend.exception.ResourceNotFoundException;
import com.expensehub.backend.repository.GroupExpenseParticipantRepository;
import com.expensehub.backend.repository.GroupExpenseRepository;
import com.expensehub.backend.repository.GroupMemberRepository;
import com.expensehub.backend.repository.GroupRepository;
import com.expensehub.backend.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.expensehub.backend.dto.GroupExpenseParticipantResponse;
import com.expensehub.backend.dto.GroupBalanceResponse;
import com.expensehub.backend.dto.SettlementResponse;
import com.expensehub.backend.dto.CreateCustomGroupExpenseRequest;
import com.expensehub.backend.repository.SettlementRepository;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class GroupExpenseService {

    private final GroupRepository groupRepository;
    private final GroupExpenseRepository groupExpenseRepository;
    private final GroupExpenseParticipantRepository participantRepository;
    private final GroupMemberRepository groupMemberRepository;
    private final UserRepository userRepository;
    private final SettlementRepository settlementRepository;

    public GroupExpenseService(
            GroupRepository groupRepository,
            GroupExpenseRepository groupExpenseRepository,
            GroupExpenseParticipantRepository participantRepository,
            GroupMemberRepository groupMemberRepository,
            UserRepository userRepository,
            SettlementRepository settlementRepository
    ) {
        this.groupRepository = groupRepository;
        this.groupExpenseRepository = groupExpenseRepository;
        this.participantRepository = participantRepository;
        this.groupMemberRepository = groupMemberRepository;
        this.userRepository = userRepository;
        this.settlementRepository = settlementRepository;
    }

    @Transactional
    public GroupExpenseResponse createEqualSplitExpense(
            UUID groupId,
            CreateGroupExpenseRequest request
    ) {

        // 1. Validate amount
        if (request.getAmount() == null ||
                request.getAmount().compareTo(BigDecimal.ZERO) <= 0) {

            throw new IllegalArgumentException(
                    "Expense amount must be greater than zero"
            );
        }

        // 2. Validate participants
        if (request.getParticipantIds() == null ||
                request.getParticipantIds().isEmpty()) {

            throw new IllegalArgumentException(
                    "At least one participant is required"
            );
        }

        // 3. Reject duplicate participant IDs
        List<UUID> participantIds =
                request.getParticipantIds();

        if (participantIds.size() !=
                participantIds.stream().distinct().count()) {

            throw new IllegalArgumentException(
                    "Duplicate participant IDs are not allowed"
            );
        }

        // 4. Find group
        Group group = groupRepository.findById(groupId)
                .orElseThrow(() ->
                        new ResourceNotFoundException("Group not found")
                );

        // 5. Validate payer
        if (request.getPaidBy() == null) {
            throw new IllegalArgumentException("Payer is required");
        }

        // 6. Find payer
        User paidBy = userRepository.findById(request.getPaidBy())
                .orElseThrow(() ->
                        new ResourceNotFoundException("Payer not found")
                );

        // 7. Verify payer is a group member
        if (!groupMemberRepository.existsByGroupIdAndUserId(
                groupId,
                paidBy.getId()
        )) {

            throw new IllegalArgumentException(
                    "Payer is not a member of this group"
            );
        }

        // 8. Verify all participants are group members
        for (UUID participantId : participantIds) {

            if (!groupMemberRepository.existsByGroupIdAndUserId(
                    groupId,
                    participantId
            )) {

                throw new IllegalArgumentException(
                        "User " + participantId +
                                " is not a member of this group"
                );
            }
        }

        // 9. Create expense
        GroupExpense expense = new GroupExpense();

        expense.setAmount(request.getAmount());
        expense.setDescription(request.getDescription());
        expense.setCategory(request.getCategory());

        if (request.getExpenseDate() != null) {
            expense.setExpenseDate(request.getExpenseDate());
        } else {
            expense.setExpenseDate(LocalDateTime.now());
        }

        expense.setGroup(group);
        expense.setPaidBy(paidBy);

        GroupExpense savedExpense =
                groupExpenseRepository.save(expense);

        // 10. Calculate equal split
        BigDecimal totalAmount =
                request.getAmount()
                        .setScale(2, RoundingMode.HALF_UP);

        int participantCount = participantIds.size();

        // Convert amount to paise/cents to avoid
        // rounding problems.
        BigDecimal amountInPaise =
                totalAmount.movePointRight(2);

        BigDecimal[] division =
                amountInPaise.divideAndRemainder(
                        BigDecimal.valueOf(participantCount)
                );

        BigDecimal baseSharePaise = division[0];

        int remainingPaise =
                division[1].intValue();

        // 11. Create participant records
        for (int i = 0; i < participantIds.size(); i++) {

            UUID participantId = participantIds.get(i);

            User participant =
                    userRepository.findById(participantId)
                            .orElseThrow(() ->
                                    new ResourceNotFoundException(
                                            "Participant not found"
                                    )
                            );

            BigDecimal sharePaise = baseSharePaise;

            // Distribute remaining paise one by one
            if (i < remainingPaise) {
                sharePaise =
                        sharePaise.add(BigDecimal.ONE);
            }

            BigDecimal shareAmount =
                    sharePaise
                            .movePointLeft(2)
                            .setScale(
                                    2,
                                    RoundingMode.UNNECESSARY
                            );

            GroupExpenseParticipant expenseParticipant =
                    new GroupExpenseParticipant();

            expenseParticipant.setGroupExpense(savedExpense);
            expenseParticipant.setUser(participant);
            expenseParticipant.setShareAmount(shareAmount);

            participantRepository.save(expenseParticipant);
        }

        // 12. Return clean response instead of entire entity graph
        return toResponse(savedExpense);
    }

    // Get participants for an expense
    public List<GroupExpenseParticipantResponse> getParticipants(
            UUID groupExpenseId
    ) {

        return participantRepository.findByGroupExpenseId(
                        groupExpenseId
                )
                .stream()
                .map(participant ->
                        new GroupExpenseParticipantResponse(
                                participant.getId(),
                                participant.getUser().getId(),
                                participant.getUser().getName(),
                                participant.getShareAmount()
                        )
                )
                .toList();
    }

    // Get all expenses for a group
    public List<GroupExpenseResponse> getGroupExpenses(
            UUID groupId
    ) {

        return groupExpenseRepository.findByGroupId(groupId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // Convert entity into a small response DTO
    private GroupExpenseResponse toResponse(
            GroupExpense expense
    ) {

        return new GroupExpenseResponse(
                expense.getId(),
                expense.getAmount(),
                expense.getDescription(),
                expense.getCategory(),
                expense.getExpenseDate(),
                expense.getGroup().getId(),
                expense.getPaidBy().getId(),
                expense.getPaidBy().getName()
        );
    }

    public List<GroupBalanceResponse> getGroupBalances(UUID groupId) {

        // 1. Check that the group exists
        if (!groupRepository.existsById(groupId)) {
            throw new ResourceNotFoundException(
                    "Group not found"
            );
        }

        // 2. Get all expenses
        List<GroupExpense> expenses =
                groupExpenseRepository.findByGroupId(groupId);

        // 3. Get all group members
        List<com.expensehub.backend.entity.GroupMember> members =
                groupMemberRepository.findByGroupId(groupId);

        // 4. Get all settlements
        List<com.expensehub.backend.entity.Settlement> settlements =
                settlementRepository.findByGroupId(groupId);

        List<GroupBalanceResponse> balances =
                new java.util.ArrayList<>();

        // =========================================================
        // CALCULATE ORIGINAL EXPENSE BALANCES
        // =========================================================

        for (com.expensehub.backend.entity.GroupMember member : members) {

            User user = member.getUser();

            BigDecimal totalPaid = BigDecimal.ZERO;
            BigDecimal totalShare = BigDecimal.ZERO;

            for (GroupExpense expense : expenses) {

                // How much this user actually paid
                if (expense.getPaidBy().getId().equals(user.getId())) {

                    totalPaid = totalPaid.add(
                            expense.getAmount()
                    );
                }

                // How much this user owes
                List<GroupExpenseParticipant> participants =
                        participantRepository.findByGroupExpenseId(
                                expense.getId()
                        );

                for (GroupExpenseParticipant participant : participants) {

                    if (participant.getUser().getId().equals(user.getId())) {

                        totalShare = totalShare.add(
                                participant.getShareAmount()
                        );
                    }
                }
            }

            BigDecimal balance =
                    totalPaid.subtract(totalShare);

            balances.add(
                    new GroupBalanceResponse(
                            user.getId(),
                            user.getName(),
                            totalPaid,
                            totalShare,
                            balance
                    )
            );
        }

        // =========================================================
        // APPLY EXISTING SETTLEMENTS
        // =========================================================

        for (com.expensehub.backend.entity.Settlement settlement
                : settlements) {

            UUID paidById =
                    settlement.getPaidBy().getId();

            UUID paidToId =
                    settlement.getPaidTo().getId();

            BigDecimal amount =
                    settlement.getAmount();

            for (int i = 0; i < balances.size(); i++) {

                GroupBalanceResponse balance =
                        balances.get(i);

                // Person who paid the settlement
                // has reduced their debt
                if (balance.getUserId().equals(paidById)) {

                    BigDecimal newBalance =
                            balance.getBalance().add(amount);

                    balances.set(
                            i,
                            new GroupBalanceResponse(
                                    balance.getUserId(),
                                    balance.getUserName(),
                                    balance.getTotalPaid(),
                                    balance.getTotalShare(),
                                    newBalance
                            )
                    );
                }

                // Person who received the settlement
                // has reduced their credit
                if (balance.getUserId().equals(paidToId)) {

                    BigDecimal newBalance =
                            balance.getBalance().subtract(amount);

                    balances.set(
                            i,
                            new GroupBalanceResponse(
                                    balance.getUserId(),
                                    balance.getUserName(),
                                    balance.getTotalPaid(),
                                    balance.getTotalShare(),
                                    newBalance
                            )
                    );
                }
            }
        }

        return balances;
    }

    public List<SettlementResponse> getSettlements(UUID groupId) {

        List<GroupBalanceResponse> balances =
                getGroupBalances(groupId);

        List<GroupBalanceResponse> creditors =
                new java.util.ArrayList<>();

        List<GroupBalanceResponse> debtors =
                new java.util.ArrayList<>();

        for (GroupBalanceResponse balance : balances) {

            if (balance.getBalance().compareTo(BigDecimal.ZERO) > 0) {
                creditors.add(balance);
            }

            if (balance.getBalance().compareTo(BigDecimal.ZERO) < 0) {
                debtors.add(balance);
            }
        }

        List<SettlementResponse> settlements =
                new java.util.ArrayList<>();

        int creditorIndex = 0;
        int debtorIndex = 0;

        while (
                creditorIndex < creditors.size()
                        &&
                        debtorIndex < debtors.size()
        ) {

            GroupBalanceResponse creditor =
                    creditors.get(creditorIndex);

            GroupBalanceResponse debtor =
                    debtors.get(debtorIndex);

            BigDecimal creditorAmount =
                    creditor.getBalance();

            BigDecimal debtorAmount =
                    debtor.getBalance().abs();

            BigDecimal settlementAmount =
                    creditorAmount.min(debtorAmount);

            settlements.add(
                    new SettlementResponse(
                            UUID.randomUUID(),
                            groupId,
                            debtor.getUserId(),
                            debtor.getUserName(),
                            creditor.getUserId(),
                            creditor.getUserName(),
                            settlementAmount,
                            java.time.LocalDateTime.now()
                    )
            );
            creditorAmount =
                    creditorAmount.subtract(
                            settlementAmount
                    );

            debtorAmount =
                    debtorAmount.subtract(
                            settlementAmount
                    );

            creditors.set(
                    creditorIndex,
                    new GroupBalanceResponse(
                            creditor.getUserId(),
                            creditor.getUserName(),
                            creditor.getTotalPaid(),
                            creditor.getTotalShare(),
                            creditorAmount
                    )
            );

            debtors.set(
                    debtorIndex,
                    new GroupBalanceResponse(
                            debtor.getUserId(),
                            debtor.getUserName(),
                            debtor.getTotalPaid(),
                            debtor.getTotalShare(),
                            debtorAmount.negate()
                    )
            );

            if (creditorAmount.compareTo(BigDecimal.ZERO) == 0) {
                creditorIndex++;
            }

            if (debtorAmount.compareTo(BigDecimal.ZERO) == 0) {
                debtorIndex++;
            }
        }

        return settlements;
    }

    @Transactional
    public GroupExpenseResponse createCustomSplitExpense(
            UUID groupId,
            CreateCustomGroupExpenseRequest request
    ) {

        // 1. Validate amount
        if (request.getAmount() == null ||
                request.getAmount().compareTo(BigDecimal.ZERO) <= 0) {

            throw new IllegalArgumentException(
                    "Expense amount must be greater than zero"
            );
        }

        // 2. Validate participants
                if (request.getParticipants() == null ||
                        request.getParticipants().isEmpty()) {

                    throw new IllegalArgumentException(
                            "At least one participant is required"
                    );
                }

        // 3. Reject duplicate participant IDs
                long uniqueParticipantCount =
                        request.getParticipants()
                                .stream()
                                .map(CreateCustomGroupExpenseRequest.CustomParticipant::getUserId)
                                .distinct()
                                .count();

                if (uniqueParticipantCount != request.getParticipants().size()) {

                    throw new IllegalArgumentException(
                            "Duplicate participant IDs are not allowed"
                    );
                }

        // 4. Find group
                Group group = groupRepository.findById(groupId)
                        .orElseThrow(() ->
                                new ResourceNotFoundException(
                                        "Group not found"
                                )
                        );
        // 4. Validate payer
        if (request.getPaidBy() == null) {

            throw new IllegalArgumentException(
                    "Payer is required"
            );
        }

        User paidBy = userRepository.findById(
                request.getPaidBy()
        ).orElseThrow(() ->
                new ResourceNotFoundException(
                        "Payer not found"
                )
        );

        // 5. Check payer is a group member
        if (!groupMemberRepository.existsByGroupIdAndUserId(
                groupId,
                paidBy.getId()
        )) {

            throw new IllegalArgumentException(
                    "Payer is not a member of this group"
            );
        }

        // 6. Calculate total of custom shares
        BigDecimal shareTotal = BigDecimal.ZERO;

        for (CreateCustomGroupExpenseRequest.CustomParticipant participant
                : request.getParticipants()) {

            if (participant.getUserId() == null) {

                throw new IllegalArgumentException(
                        "Participant user ID is required"
                );
            }

            if (participant.getShareAmount() == null ||
                    participant.getShareAmount()
                            .compareTo(BigDecimal.ZERO) < 0) {

                throw new IllegalArgumentException(
                        "Participant share cannot be negative"
                );
            }

            // Check participant is group member
            if (!groupMemberRepository.existsByGroupIdAndUserId(
                    groupId,
                    participant.getUserId()
            )) {

                throw new IllegalArgumentException(
                        "User " + participant.getUserId() +
                                " is not a member of this group"
                );
            }

            shareTotal = shareTotal.add(
                    participant.getShareAmount()
            );
        }

        // 7. Normalize amounts to 2 decimal places
        BigDecimal expenseAmount =
                request.getAmount()
                        .setScale(2, RoundingMode.HALF_UP);

        shareTotal =
                shareTotal.setScale(
                        2,
                        RoundingMode.HALF_UP
                );

        // 8. Make sure shares equal expense
        if (shareTotal.compareTo(expenseAmount) != 0) {

            throw new IllegalArgumentException(
                    "Participant shares must equal expense amount. " +
                            "Expense = " + expenseAmount +
                            ", Shares = " + shareTotal
            );
        }

        // 9. Create expense
        GroupExpense expense = new GroupExpense();

        expense.setAmount(expenseAmount);
        expense.setDescription(request.getDescription());
        expense.setCategory(request.getCategory());

        if (request.getExpenseDate() != null) {

            expense.setExpenseDate(
                    request.getExpenseDate()
            );

        } else {

            expense.setExpenseDate(
                    LocalDateTime.now()
            );
        }

        expense.setGroup(group);
        expense.setPaidBy(paidBy);

        GroupExpense savedExpense =
                groupExpenseRepository.save(expense);

        // 10. Create participant records
        for (CreateCustomGroupExpenseRequest.CustomParticipant participant
                : request.getParticipants()) {

            User user = userRepository.findById(
                    participant.getUserId()
            ).orElseThrow(() ->
                    new ResourceNotFoundException(
                            "Participant not found"
                    )
            );

            BigDecimal shareAmount =
                    participant.getShareAmount()
                            .setScale(
                                    2,
                                    RoundingMode.HALF_UP
                            );

            GroupExpenseParticipant expenseParticipant =
                    new GroupExpenseParticipant();

            expenseParticipant.setGroupExpense(
                    savedExpense
            );

            expenseParticipant.setUser(user);

            expenseParticipant.setShareAmount(
                    shareAmount
            );

            participantRepository.save(
                    expenseParticipant
            );
        }

        return toResponse(savedExpense);
    }
}