package com.expensehub.backend.controller;

import com.expensehub.backend.dto.CreateSettlementRequest;
import com.expensehub.backend.dto.SettlementResponse;
import com.expensehub.backend.service.SettlementService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/groups")
public class SettlementController {

    private final SettlementService settlementService;

    public SettlementController(
            SettlementService settlementService
    ) {
        this.settlementService = settlementService;
    }

    // =========================================================
    // CREATE SETTLEMENT
    // POST /api/groups/{groupId}/settlements
    // =========================================================

    @PostMapping("/{groupId}/settlements")
    public ResponseEntity<SettlementResponse> createSettlement(
            @PathVariable UUID groupId,
            @RequestBody CreateSettlementRequest request
    ) {

        SettlementResponse response =
                settlementService.createSettlement(
                        groupId,
                        request.getPaidById(),
                        request.getPaidToId(),
                        request.getAmount()
                );

        return ResponseEntity.ok(response);
    }


    // =========================================================
    // GET GROUP SETTLEMENTS
    // GET /api/groups/{groupId}/settlements
    // =========================================================

    @GetMapping("/{groupId}/settlements")
    public ResponseEntity<List<SettlementResponse>> getGroupSettlements(
            @PathVariable UUID groupId
    ) {

        return ResponseEntity.ok(
                settlementService.getGroupSettlements(groupId)
        );
    }
}