package com.expensehub.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "expense_splits")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ExpenseSplit {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @JdbcTypeCode(SqlTypes.VARCHAR)
    @Column(nullable = false, updatable = false, length = 36)
    private UUID id;

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal shareAmount;

    @ManyToOne
    @JoinColumn(name = "expense_id", nullable = false)
    private GroupExpense groupExpense;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
}