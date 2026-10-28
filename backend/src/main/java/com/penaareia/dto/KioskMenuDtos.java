package com.penaareia.dto;

import com.penaareia.model.Kiosk;
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

            String fotoUrl,

            Boolean destaque
    ) {
        public CreateMenuItemRequest {
            if (disponivel == null) disponivel = true;
            if (category == null || category.isBlank()) category = "Outros";
            if (returnablePackaging == null) returnablePackaging = false;
            if (destaque == null) destaque = false;
        }

        public CreateMenuItemRequest(String nome,
                                     String descricao,
                                     BigDecimal preco,
                                     Boolean disponivel,
                                     String category,
                                     Boolean returnablePackaging,
                                     String fotoUrl) {
            this(nome, descricao, preco, disponivel, category, returnablePackaging, fotoUrl, false);
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

            String fotoUrl,

            Boolean destaque
    ) {
        public UpdateMenuItemRequest {
            if (disponivel == null) disponivel = true;
            if (category == null || category.isBlank()) category = "Outros";
            if (returnablePackaging == null) returnablePackaging = false;
            if (destaque == null) destaque = false;
        }

        public UpdateMenuItemRequest(String nome,
                                     String descricao,
                                     BigDecimal preco,
                                     Boolean disponivel,
                                     String category,
                                     Boolean returnablePackaging,
                                     String fotoUrl) {
            this(nome, descricao, preco, disponivel, category, returnablePackaging, fotoUrl, false);
        }
    }

    public record MenuItemAvailabilityRequest(
            boolean disponivel
    ) {
    }

    public record UpdateStorefrontRequest(
            @Size(max = 160, message = "A descrição curta deve ter no máximo 160 caracteres.")
            String descricaoCurta,
            String fotoCapaUrl,
            String logoUrl,
            Boolean aceitaEmbalagemSustentavel,
            Boolean destaquePopular,
            String nome,
            String cnpj,
            String cep,
            String logradouro,
            String numero,
            String complemento,
            String bairro,
            String cidade,
            String uf,
            String pontoReferenciaId
    ) {
        public UpdateStorefrontRequest(String descricaoCurta,
                                       String fotoCapaUrl,
                                       String logoUrl,
                                       Boolean aceitaEmbalagemSustentavel,
                                       Boolean destaquePopular) {
            this(descricaoCurta, fotoCapaUrl, logoUrl, aceitaEmbalagemSustentavel, destaquePopular,
                    null, null, null, null, null, null, null, null, null, null);
        }
    }

    public record PartnerOnboardingRequest(
            @NotBlank(message = "O nome do quiosque/restaurante é obrigatório.")
            @Size(min = 2, max = 100, message = "O nome deve ter entre 2 e 100 caracteres.")
            String nome,
            String descricaoCurta,
            String logoUrl,
            String fotoCapaUrl,
            Boolean aceitaEmbalagemSustentavel,
            Boolean destaquePopular,
            String cnpj,
            String cep,
            String logradouro,
            String numero,
            String complemento,
            String bairro,
            String cidade,
            String uf,
            String pontoReferenciaId
    ) {
    }

    public record PartnerOnboardingResponse(
            String token,
            String userId,
            String name,
            String role,
            Kiosk kiosk
    ) {
    }
}
