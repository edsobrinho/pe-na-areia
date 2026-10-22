package com.penaareia.repository;

import com.penaareia.model.Order;
import com.penaareia.model.OrderStatus;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;
import java.util.Set;

public interface OrderRepository extends MongoRepository<Order, String> {

    List<Order> findByUserIdOrderByTimelineCriadoEmDesc(String userId);

    List<Order> findByCourierIdAndStatus(String courierId, OrderStatus status);

    List<Order> findByCourierIdAndStatusIn(
            String courierId, Set<OrderStatus> statuses, Pageable pageable);

    List<Order> findByStatus(OrderStatus status, Pageable pageable);
}
