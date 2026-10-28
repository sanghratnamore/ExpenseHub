package com.expensehub.service;

import com.expensehub.dto.CategoryRequest;
import com.expensehub.entity.Category;
import com.expensehub.entity.User;
import com.expensehub.repository.CategoryRepository;
import com.expensehub.security.CurrentUser;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class CategoryService {

    private final CategoryRepository categoryRepository;
    private final CurrentUser currentUser;

    public Category createCategory(CategoryRequest request) {
        User user = currentUser.getUser();

        Category category = Category.builder()
                .name(request.getName())
                .type(request.getType())
                .user(user)
                .build();

        return categoryRepository.save(category);
    }

    @Transactional
    public List<Category> getMyCategories() {
        User user = currentUser.getUser();

        List<Category> categories = categoryRepository.findByUserId(user.getId());

        if (categories.isEmpty()) {
            categories = createDefaultCategories(user);
        }

        return categories;
    }

    public List<Category> getCategoriesByUser(UUID userId) {
        return categoryRepository.findByUserId(userId);
    }

    public Category updateCategory(UUID categoryId, CategoryRequest request) {
        User user = currentUser.getUser();

        Category category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new RuntimeException("Category not found"));

        if (!category.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("You cannot update this category");
        }

        category.setName(request.getName());
        category.setType(request.getType());

        return categoryRepository.save(category);
    }

    public void deleteCategory(UUID categoryId) {
        User user = currentUser.getUser();

        Category category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new RuntimeException("Category not found"));

        if (!category.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("You cannot delete this category");
        }

        categoryRepository.deleteById(categoryId);
    }

    @Transactional
    public List<Category> createDefaultCategories(User user) {
        List<Category> defaults = List.of(
                Category.builder().name("Food & Dining").type("EXPENSE").user(user).build(),
                Category.builder().name("Groceries").type("EXPENSE").user(user).build(),
                Category.builder().name("Hotel").type("EXPENSE").user(user).build(),
                Category.builder().name("Travel").type("EXPENSE").user(user).build(),
                Category.builder().name("Transport").type("EXPENSE").user(user).build(),
                Category.builder().name("Shopping").type("EXPENSE").user(user).build(),
                Category.builder().name("Bills").type("EXPENSE").user(user).build(),
                Category.builder().name("Rent").type("EXPENSE").user(user).build(),
                Category.builder().name("Health").type("EXPENSE").user(user).build(),
                Category.builder().name("Education").type("EXPENSE").user(user).build(),
                Category.builder().name("Entertainment").type("EXPENSE").user(user).build(),
                Category.builder().name("Other").type("EXPENSE").user(user).build(),

                Category.builder().name("Salary").type("INCOME").user(user).build(),
                Category.builder().name("Freelance").type("INCOME").user(user).build(),
                Category.builder().name("Pocket Money").type("INCOME").user(user).build(),
                Category.builder().name("Gift").type("INCOME").user(user).build(),
                Category.builder().name("Interest").type("INCOME").user(user).build(),
                Category.builder().name("Other Income").type("INCOME").user(user).build()
        );

        return categoryRepository.saveAll(defaults);
    }
}