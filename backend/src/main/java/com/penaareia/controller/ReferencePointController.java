package com.penaareia.controller;

import com.penaareia.model.ReferencePoint;
import com.penaareia.service.ReferencePointService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import lombok.RequiredArgsConstructor;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/reference-points")
@RequiredArgsConstructor
@Validated
@Tag(name = "Pontos de referencia", description = "Postos de salvamento oficiais da orla")
public class ReferencePointController {

    private final ReferencePointService service;

    @GetMapping
    @Operation(summary = "Lista todos os postos de referencia ativos")
    public List<ReferencePoint> listar() {
        return service.listarAtivos();
    }

    @GetMapping("/nearby")
    @Operation(summary = "Sugere os postos de referencia mais proximos de um pin")
    public List<ReferencePoint> proximos(
            @RequestParam @DecimalMin("-90.0") @DecimalMax("90.0") double lat,
            @RequestParam @DecimalMin("-180.0") @DecimalMax("180.0") double lng,
            @RequestParam(defaultValue = "1.5")
            @DecimalMin("0.1") @DecimalMax("5.0") double raioKm) {
        return service.sugerirProximos(lat, lng, raioKm);
    }
}
