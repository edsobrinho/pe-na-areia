package com.penaareia.controller;

import com.penaareia.model.Kiosk;
import com.penaareia.service.PartnershipService;
import com.penaareia.service.KioskService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/kiosks")
@RequiredArgsConstructor
@Tag(name = "Quiosques", description = "Quiosques e restaurantes parceiros da orla")
public class KioskController {

    private final KioskService service;
    private final PartnershipService partnershipService;

    @GetMapping
    @Operation(summary = "Lista todos os quiosques/restaurantes parceiros ativos")
    public List<Kiosk> listar(@RequestParam(required = false) String partnershipId) {
        return partnershipId == null || partnershipId.isBlank()
                ? service.listarAtivos()
                : partnershipService.listKiosksForPartnership(partnershipId);
    }

    @GetMapping("/by-reference-point/{pontoReferenciaId}")
    @Operation(summary = "Lista quiosques vinculados a um posto de referencia especifico")
    public List<Kiosk> listarPorPosto(@PathVariable String pontoReferenciaId) {
        return service.listarPorPostoReferencia(pontoReferenciaId);
    }
}
