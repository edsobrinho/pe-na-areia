package com.penaareia.controller;

import com.penaareia.dto.ErrorResponse;
import com.penaareia.dto.UploadResponse;
import com.penaareia.service.StorageService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/uploads")
@RequiredArgsConstructor
@Tag(name = "Uploads", description = "Upload de arquivos, como a foto do local do pedido")
public class UploadController {

    private final StorageService storageService;

    @PostMapping(value = "/location-photo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Envia a foto do local do pedido (multipart/form-data, campo 'file') e retorna a URL publica")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Foto enviada com sucesso"),
            @ApiResponse(responseCode = "400", description = "Arquivo ausente, vazio ou em formato nao suportado",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
            @ApiResponse(responseCode = "413", description = "Arquivo maior que o limite de 5MB",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
            @ApiResponse(responseCode = "503", description = "Servico de upload indisponivel (Cloudinary nao configurado)",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    public ResponseEntity<UploadResponse> enviarFotoLocal(
            @Parameter(description = "Arquivo de imagem (JPEG, PNG ou WebP), ate 5MB", required = true)
            @RequestPart("file") MultipartFile file) {
        return ResponseEntity.ok(new UploadResponse(storageService.enviarFotoLocal(file)));
    }

    @PostMapping(value = "/menu-item-photo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Envia a foto de um item do cardapio (multipart/form-data, campo 'file') e retorna a URL publica")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Foto enviada com sucesso"),
            @ApiResponse(responseCode = "400", description = "Arquivo ausente, vazio ou em formato nao suportado",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
            @ApiResponse(responseCode = "413", description = "Arquivo maior que o limite de 5MB",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
            @ApiResponse(responseCode = "503", description = "Servico de upload indisponivel (Cloudinary nao configurado)",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    public ResponseEntity<UploadResponse> enviarFotoProduto(
            @Parameter(description = "Arquivo de imagem (JPEG, PNG ou WebP), ate 5MB", required = true)
            @RequestPart("file") MultipartFile file) {
        return ResponseEntity.ok(new UploadResponse(storageService.enviarFotoProduto(file)));
    }
}
