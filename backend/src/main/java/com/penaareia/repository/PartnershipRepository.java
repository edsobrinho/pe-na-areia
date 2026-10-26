package com.penaareia.repository;

import com.penaareia.model.Partnership;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface PartnershipRepository extends MongoRepository<Partnership, String> {

    List<Partnership> findByActiveTrue();
}
