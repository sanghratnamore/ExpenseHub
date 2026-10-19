package com.expensehub.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "expense_splits")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ExpenseSplit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal shareAmount;

    @ManyToOne
    @JoinColumn(name = "expense_id", nullable = false)
    private GroupExpense groupExpense;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
}