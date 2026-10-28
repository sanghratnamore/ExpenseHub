package com.expensehub.service;

import com.expensehub.dto.*;
import com.expensehub.entity.*;
import com.expensehub.exception.GroupInUseException;
import com.expensehub.repository.*;
import com.expensehub.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class GroupService {

    private final GroupRepository groupRepository;
    private final UserRepository userRepository;
    private final GroupExpenseRepository groupExpenseRepository;
    private final ExpenseSplitRepository expenseSplitRepository;
    private final SettlementRepository settlementRepository;
    private final ExpenseCalculationEngine expenseCalculationEngine;
    private final CurrentUser currentUser;
    private final CategoryRepository categoryRepository;
    private final TransactionRepository transactionRepository;
    private final GroupMemberRepository groupMemberRepository;

    @Transactional
    public GroupEntity createGroup(
            CreateGroupRequest request
    ) {
        User creator =
                userRepository.findById(
                        request.getCreatedBy()
                ).orElseThrow(() ->
                        new RuntimeException(
                                "Creator user not found"
                        )
                );

        GroupEntity group =
                GroupEntity.builder()
                        .name(request.getName())
                        .description(request.getDescription())
                        .createdDate(LocalDate.now())
                        .createdBy(creator)
                        .inviteCode(generateInviteCode())
                        .build();

        GroupEntity savedGroup =
                groupRepository.save(group);

        GroupMember adminMember =
                GroupMember.builder()
                        .group(savedGroup)
                        .user(creator)
                        .role(GroupRole.ADMIN)
                        .active(true)
                        .build();

        groupMemberRepository.save(adminMember);

        if (request.getMemberIds() != null) {
            for (UUID memberId :
                    request.getMemberIds()) {

                if (memberId.equals(
                        creator.getId()
                )) {
                    continue;
                }

                User member =
                        userRepository.findById(memberId)
                                .orElseThrow(() ->
                                        new RuntimeException(
                                                "Member not found: "
                                                        + memberId
                                        )
                                );

                GroupMember groupMember =
                        GroupMember.builder()
                                .group(savedGroup)
                                .user(member)
                                .role(GroupRole.MEMBER)
                                .active(true)
                                .build();

                groupMemberRepository.save(
                        groupMember
                );
            }
        }

        return savedGroup;
    }

    @Transactional
    public String joinGroup(
            String inviteCode
    ) {
        User user = currentUser.getUser();

        GroupEntity group =
                groupRepository.findByInviteCode(
                        inviteCode.trim().toUpperCase()
                ).orElseThrow(() ->
                        new RuntimeException(
                                "Invalid invite code"
                        )
                );

        boolean alreadyMember =
                groupMemberRepository
                        .existsByGroupIdAndUserIdAndActiveTrue(
                                group.getId(),
                                user.getId()
                        );

        if (alreadyMember) {
            throw new RuntimeException(
                    "You are already a member of this group"
            );
        }

        GroupMember member =
                GroupMember.builder()
                        .group(group)
                        .user(user)
                        .role(GroupRole.MEMBER)
                        .active(true)
                        .build();

        groupMemberRepository.save(member);

        return "Joined " + group.getName();
    }

    @Transactional(readOnly = true)
    public GroupResponse getGroupForCurrentUser(
            UUID groupId
    ) {
        User user = currentUser.getUser();

        assertGroupMember(
                groupId,
                user.getId()
        );

        GroupEntity group =
                groupRepository.findById(groupId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Group not found"
                                )
                        );

        return mapToGroupResponse(group);
    }

    @Transactional
    public void leaveGroup(UUID groupId) {
        User user = currentUser.getUser();

        assertGroupMember(groupId, user.getId());

        GroupMember member = groupMemberRepository
                .findByGroupIdAndUserId(groupId, user.getId())
                .orElseThrow(() ->
                        new RuntimeException(
                                "You are not a member of this group"
                        )
                );

        if (member.getRole() == GroupRole.ADMIN) {
            long adminCount = groupMemberRepository
                    .countByGroupIdAndRoleAndActiveTrue(
                            groupId,
                            GroupRole.ADMIN
                    );

            if (adminCount <= 1) {
                throw new RuntimeException(
                        "Assign another admin before leaving this group"
                );
            }
        }

        groupMemberRepository.delete(member);
    }

    @Transactional
    public void deleteGroup(UUID groupId) {
        User user = currentUser.getUser();

        GroupEntity group = groupRepository.findById(groupId)
                .orElseThrow(() -> new RuntimeException("Group not found"));

        if (!group.getCreatedBy().getId().equals(user.getId())) {
            throw new RuntimeException("You cannot delete this group");
        }

        expenseSplitRepository.deleteByGroupId(groupId);

        groupExpenseRepository.deleteByGroupId(groupId);

        settlementRepository.deleteByGroupId(groupId);

        groupMemberRepository.deleteByGroupId(groupId);

        groupRepository.delete(group);
    }

    @Transactional(readOnly = true)
    public List<GroupExpenseResponse> getGroupExpenses(
            UUID groupId
    ) {
        User user = currentUser.getUser();

        assertGroupMember(
                groupId,
                user.getId()
        );

        return groupExpenseRepository
                .findByGroupIdOrderByExpenseDateDesc(groupId)
                .stream()
                .map(this::mapToExpenseResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<GroupResponse> getGroupsForCurrentUser() {
        User user = currentUser.getUser();

        List<GroupEntity> groups =
                groupRepository.findGroupsByMemberId(
                        user.getId()
                );

        return groups.stream()
                .map(this::mapToGroupResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public GroupExpenseDetailResponse getGroupExpenseDetail(
            UUID groupId,
            UUID expenseId
    ) {
        User user = currentUser.getUser();

        assertGroupMember(
                groupId,
                user.getId()
        );

        GroupExpense expense =
                groupExpenseRepository
                        .findById(expenseId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Expense not found"
                                )
                        );

        if (!expense.getGroup().getId().equals(groupId)) {
            throw new RuntimeException(
                    "Expense does not belong to this group"
            );
        }

        List<ExpenseSplit> splits =
                expenseSplitRepository.findByGroupExpenseId(
                        expenseId
                );

        List<GroupExpenseSplitResponse> splitResponses =
                new ArrayList<>();

        for (ExpenseSplit split : splits) {
            splitResponses.add(
                    new GroupExpenseSplitResponse(
                            split.getId(),
                            split.getUser().getId(),
                            split.getUser().getName(),
                            split.getShareAmount().doubleValue()
                    )
            );
        }

        Category category = expense.getCategory();

        return new GroupExpenseDetailResponse(
                expense.getId(),
                expense.getDescription(),
                expense.getAmount().doubleValue(),
                expense.getExpenseDate(),
                expense.getPaidBy().getId(),
                expense.getPaidBy().getName(),
                category == null ? null : category.getId(),
                category == null ? null : category.getName(),
                splitResponses
        );
    }

    private GroupExpenseResponse mapToExpenseResponse(
            GroupExpense expense
    ) {
        User paidBy = expense.getPaidBy();
        Category category = expense.getCategory();

        return new GroupExpenseResponse(
                expense.getId(),
                expense.getDescription(),
                expense.getAmount(),
                expense.getExpenseDate(),
                paidBy.getId(),
                paidBy.getName(),
                category != null ? category.getId() : null,
                category != null ? category.getName() : null
        );
    }

    private GroupResponse mapToGroupResponse(
            GroupEntity group
    ) {
        List<GroupMember> groupMembers =
                groupMemberRepository.findByGroupIdAndActiveTrue(
                        group.getId()
                );

        List<GroupResponse.MemberResponse> members =
                groupMembers.stream()
                        .map(groupMember -> {
                            User user = groupMember.getUser();

                            return GroupResponse.MemberResponse
                                    .builder()
                                    .id(user.getId())
                                    .name(user.getName())
                                    .email(user.getEmail())
                                    .role(
                                            groupMember.getRole()
                                                    .name()
                                    )
                                    .build();
                        })
                        .toList();

        return GroupResponse.builder()
                .id(group.getId())
                .name(group.getName())
                .description(group.getDescription())
                .inviteCode(group.getInviteCode())
                .members(members)
                .build();
    }


    @Transactional
    public void removeMember(
            UUID groupId,
            UUID memberId
    ) {
        User admin = currentUser.getUser();

        assertGroupAdmin(
                groupId,
                admin.getId()
        );

        GroupMember member =
                groupMemberRepository
                        .findByGroupIdAndUserId(
                                groupId,
                                memberId
                        )
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "This user is not a member of this group"
                                )
                        );

        if (member.getRole() == GroupRole.ADMIN) {
            throw new RuntimeException(
                    "You cannot remove another admin"
            );
        }

        groupMemberRepository.delete(member);
    }

    @Transactional
    public void addMembers(
            UUID groupId,
            AddMembersRequest request
    ) {
        User admin = currentUser.getUser();

        assertGroupAdmin(
                groupId,
                admin.getId()
        );

        GroupEntity group =
                groupRepository.findById(groupId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Group not found"
                                )
                        );

        if (request.getMemberIds() == null ||
                request.getMemberIds().isEmpty()) {
            throw new RuntimeException(
                    "Select at least one member"
            );
        }

        for (UUID memberId :
                request.getMemberIds()) {

            boolean alreadyMember =
                    groupMemberRepository
                            .existsByGroupIdAndUserIdAndActiveTrue(
                                    groupId,
                                    memberId
                            );

            if (alreadyMember) {
                continue;
            }

            User member =
                    userRepository.findById(memberId)
                            .orElseThrow(() ->
                                    new RuntimeException(
                                            "User not found: "
                                                    + memberId
                                    )
                            );

            GroupMember groupMember =
                    GroupMember.builder()
                            .group(group)
                            .user(member)
                            .role(GroupRole.MEMBER)
                            .active(true)
                            .build();

            groupMemberRepository.save(groupMember);
        }
    }

    @Transactional
    public GroupExpense addGroupExpense(
            GroupExpenseRequest request
    ) {
        User loggedInUser = currentUser.getUser();

        assertGroupMember(
                request.getGroupId(),
                loggedInUser.getId()
        );

        GroupEntity group =
                groupRepository.findById(
                        request.getGroupId()
                ).orElseThrow(() ->
                        new RuntimeException(
                                "Group not found"
                        )
                );

        User paidBy =
                userRepository.findById(
                        request.getPaidBy()
                ).orElseThrow(() ->
                        new RuntimeException(
                                "Paying user not found"
                        )
                );

        Category category =
                categoryRepository.findById(
                        request.getCategoryId()
                ).orElseThrow(() ->
                        new RuntimeException(
                                "Category not found"
                        )
                );

        GroupExpense expense =
                GroupExpense.builder()
                        .description(
                                request.getDescription()
                        )
                        .amount(request.getAmount())
                        .expenseDate(
                                request.getExpenseDate()
                        )
                        .group(group)
                        .paidBy(paidBy)
                        .category(category)
                        .build();

        GroupExpense savedExpense =
                groupExpenseRepository.save(expense);

        int memberCount =
                request.getMemberIds().size();

        BigDecimal totalAmount =
                request.getAmount();

        BigDecimal baseShare = totalAmount.divide(
                BigDecimal.valueOf(memberCount),
                2,
                RoundingMode.DOWN
        );

        BigDecimal distributedAmount =
                baseShare.multiply(
                        BigDecimal.valueOf(memberCount)
                );

        BigDecimal remainder = totalAmount.subtract(
                distributedAmount
        );

        for (int i = 0; i < memberCount; i++) {
            UUID memberId =
                    request.getMemberIds().get(i);

            User member =
                    userRepository.findById(memberId)
                            .orElseThrow(() ->
                                    new RuntimeException(
                                            "Member not found: "
                                                    + memberId
                                    )
                            );

            BigDecimal shareAmount = baseShare;

            if (i == 0) {
                shareAmount =
                        baseShare.add(remainder);
            }

            ExpenseSplit split =
                    ExpenseSplit.builder()
                            .groupExpense(savedExpense)
                            .user(member)
                            .shareAmount(shareAmount)
                            .build();

            expenseSplitRepository.save(split);
        }

        return savedExpense;
    }

    @Transactional(readOnly = true)
    public List<GroupBalanceResponse> getGroupBalances(
            UUID groupId
    ) {
        User user = currentUser.getUser();

        assertGroupMember(
                groupId,
                user.getId()
        );

        return expenseCalculationEngine
                .calculateGroupBalances(groupId);
    }

    @Transactional(readOnly = true)
    public List<SettlementResponse> getSimplifiedSettlements(
            UUID groupId
    ) {
        User user = currentUser.getUser();

        assertGroupMember(
                groupId,
                user.getId()
        );

        return expenseCalculationEngine
                .calculateSimplifiedSettlements(groupId);
    }

    @Transactional
    public void deleteGroupExpense(
            UUID groupId,
            UUID expenseId
    ) {
        User user = currentUser.getUser();

        assertGroupMember(
                groupId,
                user.getId()
        );

        GroupExpense expense =
                groupExpenseRepository.findById(expenseId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Expense not found"
                                )
                        );

        if (!expense.getGroup().getId().equals(groupId)) {
            throw new RuntimeException(
                    "Expense does not belong to this group"
            );
        }

        expenseSplitRepository.deleteByGroupExpenseId(
                expense.getId()
        );

        groupExpenseRepository.delete(expense);
    }

    @Transactional
    public GroupExpense updateGroupExpense(
            UUID expenseId,
            GroupExpenseRequest request
    ) {
        User loggedInUser = currentUser.getUser();

        assertGroupMember(
                request.getGroupId(),
                loggedInUser.getId()
        );

        GroupExpense expense =
                groupExpenseRepository
                        .findById(expenseId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Expense not found"
                                )
                        );

        if (!expense.getGroup().getId()
                .equals(request.getGroupId())) {
            throw new RuntimeException(
                    "Expense does not belong to this group"
            );
        }

        User paidBy =
                userRepository.findById(
                        request.getPaidBy()
                ).orElseThrow(() ->
                        new RuntimeException(
                                "Paying user not found"
                        )
                );

        Category category =
                categoryRepository.findById(
                        request.getCategoryId()
                ).orElseThrow(() ->
                        new RuntimeException(
                                "Category not found"
                        )
                );

        expense.setDescription(
                request.getDescription()
        );

        expense.setAmount(request.getAmount());

        expense.setExpenseDate(
                request.getExpenseDate()
        );

        expense.setPaidBy(paidBy);

        expense.setCategory(category);

        GroupExpense updatedExpense =
                groupExpenseRepository.save(expense);

        expenseSplitRepository
                .deleteByGroupExpenseId(expenseId);

        List<UUID> memberIds =
                request.getMemberIds();

        if (memberIds == null ||
                memberIds.isEmpty()) {
            throw new RuntimeException(
                    "Select at least one member"
            );
        }

        int memberCount = memberIds.size();

        BigDecimal totalAmount =
                request.getAmount();

        BigDecimal baseShare = totalAmount.divide(
                BigDecimal.valueOf(memberCount),
                2,
                RoundingMode.DOWN
        );

        BigDecimal distributedAmount =
                baseShare.multiply(
                        BigDecimal.valueOf(memberCount)
                );

        BigDecimal remainder = totalAmount.subtract(
                distributedAmount
        );

        for (int i = 0; i < memberCount; i++) {
            UUID memberId = memberIds.get(i);

            User member =
                    userRepository.findById(memberId)
                            .orElseThrow(() ->
                                    new RuntimeException(
                                            "Member not found: "
                                                    + memberId
                                    )
                            );

            BigDecimal shareAmount = baseShare;

            if (i == 0) {
                shareAmount =
                        baseShare.add(remainder);
            }

            ExpenseSplit split =
                    ExpenseSplit.builder()
                            .groupExpense(updatedExpense)
                            .user(member)
                            .shareAmount(shareAmount)
                            .build();

            expenseSplitRepository.save(split);
        }

        return updatedExpense;
    }

    @Transactional
    public SettlementResponse settleUp(
            SettlementRequest request
    ) {
        User loggedInUser = currentUser.getUser();

        assertGroupMember(
                request.getGroupId(),
                loggedInUser.getId()
        );

        GroupEntity group =
                groupRepository.findById(
                        request.getGroupId()
                ).orElseThrow(() ->
                        new RuntimeException(
                                "Group not found"
                        )
                );

        User paidBy =
                userRepository.findById(
                        request.getPaidBy()
                ).orElseThrow(() ->
                        new RuntimeException(
                                "Paying user not found"
                        )
                );

        User paidTo =
                userRepository.findById(
                        request.getPaidTo()
                ).orElseThrow(() ->
                        new RuntimeException(
                                "Receiving user not found"
                        )
                );

        if (paidBy.getId().equals(paidTo.getId())) {
            throw new RuntimeException(
                    "A user cannot settle up with themselves"
            );
        }

        Settlement settlement =
                Settlement.builder()
                        .group(group)
                        .paidBy(paidBy)
                        .paidTo(paidTo)
                        .amount(request.getAmount())
                        .settlementDate(
                                request.getSettlementDate()
                        )
                        .settledAt(LocalDateTime.now())
                        .build();

        Settlement savedSettlement =
                settlementRepository.save(settlement);

        if (Boolean.TRUE.equals(
                request.getAddToPersonalFinance()
        )) {
            String transactionType;
            String description;

            if (loggedInUser.getId()
                    .equals(paidBy.getId())) {
                transactionType = "EXPENSE";

                description =
                        group.getName() + " paid "
                                + paidTo.getName();
            } else if (loggedInUser.getId()
                    .equals(paidTo.getId())) {
                transactionType = "INCOME";

                description =
                        group.getName()
                                + " received from "
                                + paidBy.getName();
            } else {
                transactionType = null;
                description = null;
            }

            if (transactionType != null) {
                Category settlementCategory =
                        getOrCreateSettlementCategory(
                                loggedInUser,
                                transactionType
                        );

                Transaction transaction =
                        Transaction.builder()
                                .type(transactionType)
                                .amount(
                                        request.getAmount()
                                )
                                .description(description)
                                .date(
                                        request.getSettlementDate()
                                )
                                .user(loggedInUser)
                                .category(
                                        settlementCategory
                                )
                                .build();

                transactionRepository.save(
                        transaction
                );
            }
        }

        return SettlementResponse.builder()
                .id(savedSettlement.getId())
                .groupId(group.getId())
                .paidByName(paidBy.getName())
                .paidToName(paidTo.getName())
                .amount(savedSettlement.getAmount())
                .settlementDate(
                        savedSettlement.getSettlementDate()
                )
                .settledAt(savedSettlement.getSettledAt())
                .message(
                        "Settlement recorded successfully"
                )
                .build();
    }

    public List<SettlementResponse> getSettlements(
            UUID groupId
    ) {
        User user = currentUser.getUser();

        assertGroupMember(
                groupId,
                user.getId()
        );

        List<Settlement> settlements =
                settlementRepository.findByGroupId(
                        groupId
                );

        List<SettlementResponse> responses =
                new ArrayList<>();

        for (Settlement settlement : settlements) {
            responses.add(
                    SettlementResponse.builder()
                            .id(settlement.getId())
                            .groupId(
                                    settlement.getGroup()
                                            .getId()
                            )
                            .paidByName(
                                    settlement.getPaidBy()
                                            .getName()
                            )
                            .paidToName(
                                    settlement.getPaidTo()
                                            .getName()
                            )
                            .amount(
                                    settlement.getAmount()
                            )
                            .settlementDate(
                                    settlement
                                            .getSettlementDate()
                            )
                            .settledAt(settlement.getSettledAt())
                            .message(
                                    "Settlement record"
                            )
                            .build()
            );
        }

        return responses;
    }

    private Category getOrCreateSettlementCategory(
            User user,
            String type
    ) {
        List<Category> userCategories =
                categoryRepository.findByUserId(
                        user.getId()
                );

        for (Category category : userCategories) {
            boolean nameMatches =
                    "Group Settlement"
                            .equalsIgnoreCase(
                                    category.getName()
                            );

            boolean typeMatches =
                    type.equalsIgnoreCase(
                            category.getType()
                    );

            if (nameMatches && typeMatches) {
                return category;
            }
        }

        Category settlementCategory =
                Category.builder()
                        .name("Group Settlement")
                        .type(type)
                        .user(user)
                        .build();

        return categoryRepository.save(
                settlementCategory
        );
    }

    private String generateInviteCode() {
        String characters =
                "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

        StringBuilder code = new StringBuilder();

        for (int i = 0; i < 8; i++) {
            int index =
                    (int) (Math.random()
                            * characters.length());

            code.append(
                    characters.charAt(index)
            );
        }

        return code.toString();
    }

    private void assertGroupMember(
            UUID groupId,
            UUID userId
    ) {
        boolean isMember =
                groupMemberRepository
                        .existsByGroupIdAndUserIdAndActiveTrue(
                                groupId,
                                userId
                        );

        if (!isMember) {
            throw new RuntimeException(
                    "You are not a member of this group"
            );
        }
    }

    private void assertGroupAdmin(
            UUID groupId,
            UUID userId
    ) {
        boolean isAdmin =
                groupMemberRepository
                        .existsByGroupIdAndUserIdAndRoleAndActiveTrue(
                                groupId,
                                userId,
                                GroupRole.ADMIN
                        );

        if (!isAdmin) {
            throw new RuntimeException(
                    "Only group admins can perform this action"
            );
        }
    }
}