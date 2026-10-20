package com.penaareia.service;

import com.penaareia.dto.AuthDtos.AuthResponse;
import com.penaareia.dto.AuthDtos.LoginRequest;
import com.penaareia.dto.AuthDtos.RegisterRequest;
import com.penaareia.dto.AuthDtos.Role;
import com.penaareia.model.Courier;
import com.penaareia.model.User;
import com.penaareia.repository.CourierRepository;
import com.penaareia.repository.UserRepository;
import com.penaareia.security.JwtService;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Locale;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final CourierRepository courierRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthService(UserRepository userRepository,
                       CourierRepository courierRepository,
                       PasswordEncoder passwordEncoder,
                       JwtService jwtService) {
        this.userRepository = userRepository;
        this.courierRepository = courierRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    public AuthResponse register(RegisterRequest request) {
        Role role = parseRole(request.role());
        String email = request.email().trim().toLowerCase(Locale.ROOT);
        if (userRepository.findByEmail(email).isPresent()
                || courierRepository.findByEmail(email).isPresent()) {
            throw new BusinessRuleException("E-mail já cadastrado.");
        }
        String passwordHash = passwordEncoder.encode(request.password());

        try {
            if (role == Role.CLIENT) {
                User user = new User();
                user.setNome(request.name().trim());
                user.setEmail(email);
                user.setTelefone(request.phone().trim());
                user.setSenhaHash(passwordHash);
                user.setAtivo(true);
                user = userRepository.save(user);
                return response(user.getId(), user.getNome(), user.getEmail(), "CLIENT");
            }

            if (request.vehicle() == null || request.vehicle().isBlank()) {
                throw new BusinessRuleException("Informe o veículo do entregador (PE ou BIKE).");
            }
            Courier courier = new Courier();
            courier.setNome(request.name().trim());
            courier.setEmail(email);
            courier.setTelefone(request.phone().trim());
            courier.setSenhaHash(passwordHash);
            courier.setVeiculo(parseVehicle(request.vehicle()));
            courier.setStatus(Courier.CourierStatus.DISPONIVEL);
            courier = courierRepository.save(courier);
            return response(courier.getId(), courier.getNome(), courier.getEmail(), "COURIER");
        } catch (DuplicateKeyException exception) {
            throw new BusinessRuleException("E-mail já cadastrado.");
        }
    }

    public AuthResponse login(LoginRequest request) {
        String email = request.email().trim().toLowerCase(Locale.ROOT);
        var user = userRepository.findByEmail(email);
        if (user.isPresent() && user.get().isAtivo()
                && passwordEncoder.matches(request.password(), user.get().getSenhaHash())) {
            User authenticated = user.get();
            return response(authenticated.getId(), authenticated.getNome(), email, "CLIENT");
        }

        var courier = courierRepository.findByEmail(email);
        if (courier.isPresent()
                && passwordEncoder.matches(request.password(), courier.get().getSenhaHash())) {
            Courier authenticated = courier.get();
            return response(authenticated.getId(), authenticated.getNome(), email, "COURIER");
        }
        throw new BusinessRuleException("Credenciais inválidas.");
    }

    private AuthResponse response(String id, String name, String email, String role) {
        return new AuthResponse(jwtService.generateToken(id, email, role), id, name, role);
    }

    private Role parseRole(String role) {
        try {
            return Role.valueOf(role.trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException exception) {
            throw new BusinessRuleException("Perfil inválido: use CLIENT ou COURIER.");
        }
    }

    private Courier.VehicleType parseVehicle(String vehicle) {
        return switch (vehicle.trim().toUpperCase(Locale.ROOT)) {
            case "PE", "A_PE" -> Courier.VehicleType.A_PE;
            case "BIKE", "BICICLETA" -> Courier.VehicleType.BICICLETA;
            default -> throw new BusinessRuleException("Veículo inválido: use PE ou BIKE.");
        };
    }
}
