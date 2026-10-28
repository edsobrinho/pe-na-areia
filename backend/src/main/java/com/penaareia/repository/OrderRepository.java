package com.penaareia.repository;

import com.penaareia.model.Order;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.Optional;

public interface OrderRepository extends MongoRepository<Order, String> {

    Optional<Order> findByPixTxId(String pixTxId);
}
