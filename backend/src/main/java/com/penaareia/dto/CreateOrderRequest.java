package com.penaareia.dto;

import com.penaareia.model.PaymentMethod;
import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.List;

@Data
public class CreateOrderRequest {

    @NotBlank
    private String userId;

    @NotBlank
    private String kioskId;

    @NotBlank(message = "Selecione uma parceria")
    private String partnershipId;

    @NotEmpty(message = "O pedido precisa ter ao menos um item")
    @Valid
    private List<@NotNull(message = "Item do pedido nao pode ser nulo") ItemRequest> itens;

    @NotNull
    private PaymentMethod formaPagamento;

    private boolean embalagemSustentavel;

    // --- Localizacao ---
    @NotNull(message = "O pin do cliente e obrigatorio")
    @Valid
    private PinClienteRequest pinCliente;

    @NotBlank(message = "Selecione o posto de referencia mais proximo")
    private String pontoReferenciaId;

    /** Opcional - ate 140 caracteres */
    @Size(max = 140, message = "A descricao do local deve ter no maximo 140 caracteres")
    private String descricaoLocal;

    /** Opcional - URL da foto ja enviada para o storage (POST /uploads/location-photo) */
    private String fotoLocalUrl;

    @Data
    public static class ItemRequest {
        @NotBlank
        private String menuItemId;

        @NotNull
        @Positive(message = "A quantidade deve ser maior que zero")
        private Integer quantidade;
    }

    @Data
    public static class PinClienteRequest {
        @NotNull(message = "Latitude do pin e obrigatoria")
        @DecimalMin(value = "-90.0", message = "Latitude deve estar entre -90 e 90")
        @DecimalMax(value = "90.0", message = "Latitude deve estar entre -90 e 90")
        private Double latitude;

        @NotNull(message = "Longitude do pin e obrigatoria")
        @DecimalMin(value = "-180.0", message = "Longitude deve estar entre -180 e 180")
        @DecimalMax(value = "180.0", message = "Longitude deve estar entre -180 e 180")
        private Double longitude;
    }
}
