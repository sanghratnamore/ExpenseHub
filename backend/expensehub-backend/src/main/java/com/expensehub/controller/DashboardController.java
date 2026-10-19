package com.expensehub.controller;

import com.expensehub.dto.DashboardResponse;
import com.expensehub.service.DashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final DashboardService dashboardService;

    @GetMapping("/user/{userId}")
    public ResponseEntity<DashboardResponse> getDashboard(
            @PathVariable Long userId,
            @RequestParam int year,
            @RequestParam int month
    ) {
        return ResponseEntity.ok(
                dashboardService.getMonthlyDashboard(userId, year, month)
        );
    }
}