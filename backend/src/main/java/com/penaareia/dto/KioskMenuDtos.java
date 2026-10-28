package com.penaareia.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

public class KioskMenuDtos {

    public record CreateMenuItemRequest(
            @NotBlank(message = "O nome do item é obrigatório.")
            @Size(min = 2, max = 100, message = "O nome deve ter entre 2 e 100 caracteres.")
            String nome,

            @Size(max = 255, message = "A descrição não pode ultrapassar 255 caracteres.")
            String descricao,

            @NotNull(message = "O preço é obrigatório.")
            @DecimalMin(value = "0.01", message = "O preço deve ser maior que zero.")
            BigDecimal preco,

            Boolean disponivel,

            String category,

            Boolean returnablePackaging,

            String fotoUrl
    ) {
        public CreateMenuItemRequest {
            if (disponivel == null) disponivel = true;
            if (category == null || category.isBlank()) category = "Outros";
            if (returnablePackaging == null) returnablePackaging = false;
        }
    }

    public record UpdateMenuItemRequest(
            @NotBlank(message = "O nome do item é obrigatório.")
            @Size(min = 2, max = 100, message = "O nome deve ter entre 2 e 100 caracteres.")
            String nome,

            @Size(max = 255, message = "A descrição não pode ultrapassar 255 caracteres.")
            String descricao,

            @NotNull(message = "O preço é obrigatório.")
            @DecimalMin(value = "0.01", message = "O preço deve ser maior que zero.")
            BigDecimal preco,

            Boolean disponivel,

            String category,

            Boolean returnablePackaging,

            String fotoUrl
    ) {
        public UpdateMenuItemRequest {
            if (disponivel == null) disponivel = true;
            if (category == null || category.isBlank()) category = "Outros";
            if (returnablePackaging == null) returnablePackaging = false;
        }
    }

    public record MenuItemAvailabilityRequest(
            boolean disponivel
    ) {
    }
}

