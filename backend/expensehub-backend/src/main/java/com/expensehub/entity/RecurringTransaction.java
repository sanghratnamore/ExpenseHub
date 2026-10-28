package com.expensehub.entity;


import jakarta.persistence.*;
import lombok.Getter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;


import java.time.LocalDate;
import java.util.UUID;


@Getter
@Entity
@Table(name = "recurring_transactions")
public class RecurringTransaction {


    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @JdbcTypeCode(SqlTypes.VARCHAR)
    @Column(nullable = false, updatable = false, length = 36)
    private UUID id;


    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "category_id")
    private UUID categoryId;

    public void setCategoryId(UUID categoryId) {
        this.categoryId = categoryId;
    }

    private String title;


    private Double amount;


    private String type;


    private String category;


    private String description;


    private String frequency;


    private LocalDate startDate;


    private LocalDate nextDueDate;


    private boolean active = true;


    public void setUser(User user) {
        this.user = user;
    }


    public void setTitle(String title) {
        this.title = title;
    }


    public void setAmount(Double amount) {
        this.amount = amount;
    }


    public void setType(String type) {
        this.type = type;
    }


    public void setCategory(String category) {
        this.category = category;
    }


    public void setDescription(String description) {
        this.description = description;
    }


    public void setFrequency(String frequency) {
        this.frequency = frequency;
    }


    public void setStartDate(LocalDate startDate) {
        this.startDate = startDate;
    }


    public void setNextDueDate(LocalDate nextDueDate) {
        this.nextDueDate = nextDueDate;
    }


    public void setActive(boolean active) {
        this.active = active;
    }
}