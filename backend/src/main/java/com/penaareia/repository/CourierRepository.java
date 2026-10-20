package com.penaareia.repository;

import com.penaareia.model.Courier;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.Optional;

public interface CourierRepository extends MongoRepository<Courier, String> {
    Optional<Courier> findByEmail(String email);
}
