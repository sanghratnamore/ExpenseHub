package com.expensehub.backend.service;

import com.expensehub.backend.dto.SettlementResponse;
import com.expensehub.backend.entity.Group;
import com.expensehub.backend.entity.GroupExpense;
import com.expensehub.backend.entity.GroupExpenseParticipant;
import com.expensehub.backend.entity.Settlement;
import com.expensehub.backend.entity.User;
import com.expensehub.backend.exception.ResourceNotFoundException;
import com.expensehub.backend.repository.GroupExpenseParticipantRepository;
import com.expensehub.backend.repository.GroupExpenseRepository;
import com.expensehub.backend.repository.GroupMemberRepository;
import com.expensehub.backend.repository.GroupRepository;
import com.expensehub.backend.repository.SettlementRepository;
import com.expensehub.backend.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.UUID;

@Service
public class SettlementService {

    private final SettlementRepository settlementRepository;
    private final GroupRepository groupRepository;
    private final GroupMemberRepository groupMemberRepository;
    private final UserRepository userRepository;
    private final GroupExpenseRepository groupExpenseRepository;
    private final GroupExpenseParticipantRepository participantRepository;

    public SettlementService(
            SettlementRepository settlementRepository,
            GroupRepository groupRepository,
            GroupMemberRepository groupMemberRepository,
            UserRepository userRepository,
            GroupExpenseRepository groupExpenseRepository,
            GroupExpenseParticipantRepository participantRepository
    ) {
        this.settlementRepository = settlementRepository;
        this.groupRepository = groupRepository;
        this.groupMemberRepository = groupMemberRepository;
        this.userRepository = userRepository;
        this.groupExpenseRepository = groupExpenseRepository;
        this.participantRepository = participantRepository;
    }

    // =========================================================
    // CREATE SETTLEMENT
    // =========================================================

    @Transactional
    public SettlementResponse createSettlement(
            UUID groupId,
            UUID paidById,
            UUID paidToId,
            BigDecimal amount
    ) {

        // 1. Validate IDs
        if (groupId == null) {
            throw new IllegalArgumentException(
                    "Group ID is required"
            );
        }

        if (paidById == null || paidToId == null) {
            throw new IllegalArgumentException(
                    "Payer and receiver are required"
            );
        }

        // 2. Validate amount
        if (amount == null ||
                amount.compareTo(BigDecimal.ZERO) <= 0) {

            throw new IllegalArgumentException(
                    "Settlement amount must be greater than zero"
            );
        }

        // 3. Payer and receiver cannot be same
        if (paidById.equals(paidToId)) {
            throw new IllegalArgumentException(
                    "Payer and receiver cannot be the same user"
            );
        }

        // 4. Find group
        Group group = groupRepository.findById(groupId)
                .orElseThrow(() ->
                        new ResourceNotFoundException(
                                "Group not found"
                        )
                );

        // 5. Find payer
        User paidBy = userRepository.findById(paidById)
                .orElseThrow(() ->
                        new ResourceNotFoundException(
                                "Payer not found"
                        )
                );

        // 6. Find receiver
        User paidTo = userRepository.findById(paidToId)
                .orElseThrow(() ->
                        new ResourceNotFoundException(
                                "Receiver not found"
                        )
                );

        // 7. Check payer is group member
        if (!groupMemberRepository.existsByGroupIdAndUserId(
                groupId,
                paidById
        )) {
            throw new IllegalArgumentException(
                    "Payer is not a member of this group"
            );
        }

        // 8. Check receiver is group member
        if (!groupMemberRepository.existsByGroupIdAndUserId(
                groupId,
                paidToId
        )) {
            throw new IllegalArgumentException(
                    "Receiver is not a member of this group"
            );
        }

        // 9. Normalize amount
        BigDecimal settlementAmount =
                amount.setScale(
                        2,
                        RoundingMode.HALF_UP
                );

        // =====================================================
        // 10. CALCULATE PAYER CURRENT BALANCE
        // =====================================================

        BigDecimal totalPaid = BigDecimal.ZERO;
        BigDecimal totalShare = BigDecimal.ZERO;

        List<GroupExpense> expenses =
                groupExpenseRepository.findByGroupId(groupId);

        for (GroupExpense expense : expenses) {

            // Money paid by this user
            if (expense.getPaidBy()
                    .getId()
                    .equals(paidById)) {

                totalPaid = totalPaid.add(
                        expense.getAmount()
                );
            }

            // Money owed by this user
            List<GroupExpenseParticipant> participants =
                    participantRepository.findByGroupExpenseId(
                            expense.getId()
                    );

            for (GroupExpenseParticipant participant :
                    participants) {

                if (participant.getUser()
                        .getId()
                        .equals(paidById)) {

                    totalShare = totalShare.add(
                            participant.getShareAmount()
                    );
                }
            }
        }

        // Original balance
        BigDecimal currentBalance =
                totalPaid.subtract(totalShare);

        // =====================================================
        // 11. APPLY PREVIOUS SETTLEMENTS
        // =====================================================

        List<Settlement> settlements =
                settlementRepository.findByGroupId(groupId);

        for (Settlement settlement : settlements) {

            // If payer previously paid someone,
            // their debt decreases.
            if (settlement.getPaidBy()
                    .getId()
                    .equals(paidById)) {

                currentBalance =
                        currentBalance.add(
                                settlement.getAmount()
                        );
            }

            // If payer previously received money,
            // their credit decreases.
            if (settlement.getPaidTo()
                    .getId()
                    .equals(paidById)) {

                currentBalance =
                        currentBalance.subtract(
                                settlement.getAmount()
                        );
            }
        }

        currentBalance =
                currentBalance.setScale(
                        2,
                        RoundingMode.HALF_UP
                );

        // =====================================================
        // 12. PAYER MUST OWE MONEY
        // =====================================================

        if (currentBalance.compareTo(BigDecimal.ZERO) >= 0) {

            throw new IllegalArgumentException(
                    "This user does not currently owe money"
            );
        }

        // Amount actually owed
        BigDecimal amountOwed =
                currentBalance.abs();

        // =====================================================
        // 13. PREVENT OVER-SETTLEMENT
        // =====================================================

        if (settlementAmount.compareTo(amountOwed) > 0) {

            throw new IllegalArgumentException(
                    "Settlement amount cannot be greater than " +
                            "the amount owed. Amount owed = " +
                            amountOwed
            );
        }

        // =====================================================
        // 14. CREATE SETTLEMENT
        // =====================================================

        Settlement settlement = new Settlement();

        settlement.setGroup(group);
        settlement.setPaidBy(paidBy);
        settlement.setPaidTo(paidTo);
        settlement.setAmount(settlementAmount);

        Settlement savedSettlement =
                settlementRepository.save(settlement);

        // =====================================================
        // 15. RETURN RESPONSE
        // =====================================================

        return toResponse(savedSettlement);
    }

    // =========================================================
    // GET ALL SETTLEMENTS OF A GROUP
    // =========================================================

    public List<SettlementResponse> getGroupSettlements(
            UUID groupId
    ) {

        if (!groupRepository.existsById(groupId)) {

            throw new ResourceNotFoundException(
                    "Group not found"
            );
        }

        return settlementRepository
                .findByGroupId(groupId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // =========================================================
    // ENTITY -> RESPONSE DTO
    // =========================================================

    private SettlementResponse toResponse(
            Settlement settlement
    ) {

        return new SettlementResponse(
                settlement.getId(),
                settlement.getGroup().getId(),
                settlement.getPaidBy().getId(),
                settlement.getPaidBy().getName(),
                settlement.getPaidTo().getId(),
                settlement.getPaidTo().getName(),
                settlement.getAmount(),
                settlement.getCreatedAt()
        );
    }
}