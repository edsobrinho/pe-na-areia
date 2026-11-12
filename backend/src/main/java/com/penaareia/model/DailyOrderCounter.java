package com.penaareia.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "daily_order_counters")
public class DailyOrderCounter {

    @Id
    private String id; // ex: "order_seq_2026-11-11"
    private long seq;
}
