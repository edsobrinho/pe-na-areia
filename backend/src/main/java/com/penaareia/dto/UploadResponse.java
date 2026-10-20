package com.penaareia.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Resposta do upload de foto do local (POST /uploads/location-photo).
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UploadResponse {

    /** URL publica (HTTPS) da imagem enviada */
    private String secureUrl;
}
