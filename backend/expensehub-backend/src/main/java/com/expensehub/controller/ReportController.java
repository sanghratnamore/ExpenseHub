package com.expensehub.controller;


import com.expensehub.dto.DashboardResponse;
import com.expensehub.security.CurrentUser;
import com.expensehub.service.ExpenseCalculationEngine;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;


@RestController
@RequestMapping("/api/reports")
@RequiredArgsConstructor
public class ReportController {


    private final ExpenseCalculationEngine
            expenseCalculationEngine;
    private final CurrentUser currentUser;


    @GetMapping("/monthly")
    public ResponseEntity<DashboardResponse>
    getMonthlyReport(
            @RequestParam int year,
            @RequestParam int month
    ) {
        UUID userId = currentUser.getUser().getId();


        return ResponseEntity.ok(
                expenseCalculationEngine
                        .calculateMonthlyDashboard(
                                userId,
                                year,
                                month
                        )
        );
    }
}