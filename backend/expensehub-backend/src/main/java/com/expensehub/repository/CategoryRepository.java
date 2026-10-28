package com.expensehub.repository;

import com.expensehub.entity.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import com.expensehub.entity.User;
import java.util.Optional;
import java.util.List;
import java.util.UUID;

public interface CategoryRepository extends JpaRepository<Category, UUID> {
    List<Category> findByUserId(UUID userId);
    boolean existsByUserIdAndNameAndType(UUID userId, String name, String type);
    java.util.Optional<Category> findByUserAndName(
            com.expensehub.entity.User user,
            String name
    );

    Optional<Category> findByNameAndUser(
            String name,
            User user
    );


}