package com.penaareia.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.mapping.Document;

import java.math.BigDecimal;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "kiosk_partnerships")
@CompoundIndex(name = "kiosk_partnership_unique_idx", def = "{'kioskId': 1, 'partnershipId': 1}", unique = true)
public class KioskPartnership {

    @Id
    private String id;

    private String kioskId;

    private String partnershipId;

    private boolean active;

    private BigDecimal commissionPercent = BigDecimal.ZERO;

    private BigDecimal deliveryFee = BigDecimal.ZERO;

    private DeliveryFeePayer deliveryFeePayer = DeliveryFeePayer.CLIENT;

    private BigDecimal minimumOrder = BigDecimal.ZERO;

    private int maxItemsPerOrder = 50;

    private LocalTime acceptFrom = LocalTime.MIN;

    private LocalTime acceptUntil = LocalTime.of(23, 59);

    private int prepMinutes;

    private Filters filters = new Filters();

    private List<String> productIds = new ArrayList<>();

    public enum DeliveryFeePayer {
        CLIENT,
        KIOSK
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Filters {
        private List<String> categories = new ArrayList<>();
        private boolean onlyReturnable;
    }
}
