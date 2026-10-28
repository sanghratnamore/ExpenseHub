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
import java.util.UUID;

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

    @GetMapping("/me")
    public ResponseEntity<List<Category>> getMyCategories() {
        return ResponseEntity.ok(categoryService.getMyCategories());
    }



    @PutMapping("/{categoryId}")
    public ResponseEntity<Category> updateCategory(
            @PathVariable UUID categoryId,
            @Valid @RequestBody CategoryRequest request
    ) {
        return ResponseEntity.ok(
                categoryService.updateCategory(categoryId, request)
        );
    }


    @DeleteMapping("/{categoryId}")
    public ResponseEntity<Void> deleteCategory(
            @PathVariable UUID categoryId
    ) {
        categoryService.deleteCategory(categoryId);
        return ResponseEntity.noContent().build();
    }
}