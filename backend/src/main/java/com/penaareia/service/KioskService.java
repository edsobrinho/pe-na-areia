package com.penaareia.service;

import com.penaareia.model.Kiosk;
import com.penaareia.repository.KioskRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class KioskService {

    private final KioskRepository repository;

    public List<Kiosk> listarAtivos() {
        return repository.findByAtivoTrue();
    }

    public List<Kiosk> listarPorPostoReferencia(String pontoReferenciaId) {
        return repository.findByPontoReferenciaIdAndAtivoTrue(pontoReferenciaId);
    }
}
