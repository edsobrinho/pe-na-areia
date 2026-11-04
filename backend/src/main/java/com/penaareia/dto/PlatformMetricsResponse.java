package com.penaareia.dto;

import java.math.BigDecimal;

public record PlatformMetricsResponse(
        long totalOrders,
        long totalDelivered,
        BigDecimal averageFoodRating,
        BigDecimal averageDeliveryRating,
        long totalReviews
) {
}

