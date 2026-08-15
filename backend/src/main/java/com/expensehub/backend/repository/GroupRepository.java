package com.expensehub.backend.repository;

import com.expensehub.backend.entity.Group;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface GroupRepository extends JpaRepository<Group, UUID> {

    List<Group> findByCreatedById(UUID userId);
}