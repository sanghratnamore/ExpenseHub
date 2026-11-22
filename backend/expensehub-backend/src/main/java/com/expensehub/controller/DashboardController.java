package com.expensehub.controller;

import com.expensehub.dto.DashboardResponse;
import com.expensehub.service.DashboardService;
import lombok.RequiredArgsConstructor;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.expensehub.entity.User;

@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final DashboardService dashboardService;

    @GetMapping("/me")
    public ResponseEntity<DashboardResponse> getDashboard(
            @RequestParam int year,
            @RequestParam int month
    ) {
        return ResponseEntity.ok(
                dashboardService.getMonthlyDashboardForCurrentUser(year, month)
        );
    }
}