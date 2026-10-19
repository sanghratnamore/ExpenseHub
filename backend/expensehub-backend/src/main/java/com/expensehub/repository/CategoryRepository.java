package com.expensehub.repository;

import com.expensehub.entity.Category;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CategoryRepository extends JpaRepository<Category, Long> {
    List<Category> findByUserId(Long userId);
    boolean existsByUserIdAndNameAndType(Long userId, String name, String type);
}