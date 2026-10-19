package com.expensehub.controller;

import com.expensehub.dto.CategoryRequest;
import com.expensehub.entity.Category;
import com.expensehub.service.CategoryService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/categories")
@RequiredArgsConstructor
public class CategoryController {

    private final CategoryService categoryService;

    @PostMapping
    public ResponseEntity<Category> createCategory(
            @Valid @RequestBody CategoryRequest request
    ) {
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(categoryService.createCategory(request));
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<Category>> getCategories(
            @PathVariable Long userId
    ) {
        return ResponseEntity.ok(categoryService.getCategoriesByUser(userId));
    }
}