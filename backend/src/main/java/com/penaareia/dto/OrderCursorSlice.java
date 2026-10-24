package com.penaareia.dto;

import com.penaareia.model.Order;

import java.util.List;

public record OrderCursorSlice(List<Order> orders, String nextCursor) {
}
