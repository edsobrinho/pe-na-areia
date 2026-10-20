package com.penaareia.controller;

import com.penaareia.model.ReferencePoint;
import com.penaareia.service.ReferencePointService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/reference-points")
@RequiredArgsConstructor
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
            @RequestParam double lat,
            @RequestParam double lng,
            @RequestParam(defaultValue = "1.5") double raioKm) {
        return service.sugerirProximos(lat, lng, raioKm);
    }
}
