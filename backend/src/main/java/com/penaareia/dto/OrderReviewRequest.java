package com.penaareia.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record OrderReviewRequest(
        @NotNull(message = "A nota do pedido/quiosque é obrigatória")
        @Min(value = 1, message = "A nota mínima é 1 estrela")
        @Max(value = 5, message = "A nota máxima é 5 estrelas")
        Integer notaPedido,

        @NotNull(message = "A nota da entrega é obrigatória")
        @Min(value = 1, message = "A nota mínima é 1 estrela")
        @Max(value = 5, message = "A nota máxima é 5 estrelas")
        Integer notaEntrega,

        @Size(max = 300, message = "O comentário pode ter no máximo 300 caracteres")
        String comentario
) {
}

