package com.penaareia.service;

import com.penaareia.dto.AuthDtos.AuthResponse;
import com.penaareia.dto.AuthDtos.LoginRequest;
import com.penaareia.dto.AuthDtos.RegisterRequest;
import com.penaareia.model.Courier;
import com.penaareia.model.User;
import com.penaareia.repository.CourierRepository;
import com.penaareia.repository.UserRepository;
import com.penaareia.security.JwtService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private CourierRepository courierRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtService jwtService;

    @InjectMocks
    private AuthService service;

    @Test
    void registrarClienteNormalizaDadosArmazenaHashESegueComToken() {
        when(userRepository.findByEmail("ana@example.com")).thenReturn(Optional.empty());
        when(courierRepository.findByEmail("ana@example.com")).thenReturn(Optional.empty());
        when(passwordEncoder.encode("secret1")).thenReturn("encoded-password");
        when(jwtService.generateToken("user-1", "ana@example.com", "CLIENT")).thenReturn("jwt-token");
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User user = invocation.getArgument(0);
            user.setId("user-1");
            return user;
        });

        AuthResponse response = service.register(new RegisterRequest(
                " Ana ", " ANA@EXAMPLE.COM ", " 13999990000 ", "secret1", " client ", null));

        ArgumentCaptor<User> userCaptor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(userCaptor.capture());
        User savedUser = userCaptor.getValue();
        assertThat(savedUser.getNome()).isEqualTo("Ana");
        assertThat(savedUser.getEmail()).isEqualTo("ana@example.com");
        assertThat(savedUser.getTelefone()).isEqualTo("13999990000");
        assertThat(savedUser.getSenhaHash()).isEqualTo("encoded-password");
        assertThat(savedUser.isAtivo()).isTrue();
        assertThat(response).isEqualTo(new AuthResponse("jwt-token", "user-1", "Ana", "CLIENT"));
        verify(jwtService).generateToken("user-1", "ana@example.com", "CLIENT");
        verify(courierRepository, never()).save(any(Courier.class));
    }

    @Test
    void registrarEntregadorConverteBicicletaEDefineDisponivel() {
        when(userRepository.findByEmail("leo@example.com")).thenReturn(Optional.empty());
        when(courierRepository.findByEmail("leo@example.com")).thenReturn(Optional.empty());
        when(passwordEncoder.encode("secret1")).thenReturn("encoded-password");
        when(jwtService.generateToken("courier-1", "leo@example.com", "COURIER")).thenReturn("jwt-token");
        when(courierRepository.save(any(Courier.class))).thenAnswer(invocation -> {
            Courier courier = invocation.getArgument(0);
            courier.setId("courier-1");
            return courier;
        });

        AuthResponse response = service.register(new RegisterRequest(
                "Leo", "leo@example.com", "13999990000", "secret1", "COURIER", " bicicleta "));

        ArgumentCaptor<Courier> courierCaptor = ArgumentCaptor.forClass(Courier.class);
        verify(courierRepository).save(courierCaptor.capture());
        assertThat(courierCaptor.getValue().getVeiculo()).isEqualTo(Courier.VehicleType.BICICLETA);
        assertThat(courierCaptor.getValue().getStatus()).isEqualTo(Courier.CourierStatus.DISPONIVEL);
        assertThat(response.role()).isEqualTo("COURIER");
        verify(jwtService).generateToken("courier-1", "leo@example.com", "COURIER");
    }

    @Test
    void registrarEntregadorAceitaVeiculoAPe() {
        when(userRepository.findByEmail("leo@example.com")).thenReturn(Optional.empty());
        when(courierRepository.findByEmail("leo@example.com")).thenReturn(Optional.empty());
        when(passwordEncoder.encode("secret1")).thenReturn("encoded-password");
        when(courierRepository.save(any(Courier.class))).thenAnswer(invocation -> invocation.getArgument(0));

        service.register(new RegisterRequest(
                "Leo", "leo@example.com", "13999990000", "secret1", "COURIER", "a_pe"));

        ArgumentCaptor<Courier> courierCaptor = ArgumentCaptor.forClass(Courier.class);
        verify(courierRepository).save(courierCaptor.capture());
        assertThat(courierCaptor.getValue().getVeiculo()).isEqualTo(Courier.VehicleType.A_PE);
    }

    @Test
    void registrarRecusaEmailJaCadastradoParaCliente() {
        when(userRepository.findByEmail("ana@example.com")).thenReturn(Optional.of(new User()));

        assertThatThrownBy(() -> service.register(new RegisterRequest(
                "Ana", "ANA@example.com", "13999990000", "secret1", "CLIENT", null)))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessage("E-mail já cadastrado.");

        verify(courierRepository, never()).findByEmail(any());
        verify(userRepository, never()).save(any(User.class));
    }

    @Test
    void registrarRecusaEmailJaCadastradoParaEntregador() {
        when(userRepository.findByEmail("leo@example.com")).thenReturn(Optional.empty());
        when(courierRepository.findByEmail("leo@example.com")).thenReturn(Optional.of(new Courier()));

        assertThatThrownBy(() -> service.register(new RegisterRequest(
                "Leo", "leo@example.com", "13999990000", "secret1", "COURIER", "PE")))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessage("E-mail já cadastrado.");

        verify(courierRepository, never()).save(any(Courier.class));
    }

    @Test
    void registrarRecusaPerfilInvalido() {
        assertThatThrownBy(() -> service.register(new RegisterRequest(
                "Ana", "ana@example.com", "13999990000", "secret1", "ADMIN", null)))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessage("Perfil inválido: use CLIENT ou COURIER.");

        verify(userRepository, never()).findByEmail(any());
    }

    @Test
    void registrarEntregadorExigeVeiculo() {
        when(userRepository.findByEmail("leo@example.com")).thenReturn(Optional.empty());
        when(courierRepository.findByEmail("leo@example.com")).thenReturn(Optional.empty());
        when(passwordEncoder.encode("secret1")).thenReturn("encoded-password");

        assertThatThrownBy(() -> service.register(new RegisterRequest(
                "Leo", "leo@example.com", "13999990000", "secret1", "COURIER", "  ")))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessage("Informe o veículo do entregador (PE ou BIKE).");

        verify(courierRepository, never()).save(any(Courier.class));
    }

    @Test
    void registrarEntregadorRecusaVeiculoDesconhecido() {
        when(userRepository.findByEmail("leo@example.com")).thenReturn(Optional.empty());
        when(courierRepository.findByEmail("leo@example.com")).thenReturn(Optional.empty());
        when(passwordEncoder.encode("secret1")).thenReturn("encoded-password");

        assertThatThrownBy(() -> service.register(new RegisterRequest(
                "Leo", "leo@example.com", "13999990000", "secret1", "COURIER", "CARRO")))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessage("Veículo inválido: use PE ou BIKE.");

        verify(courierRepository, never()).save(any(Courier.class));
    }

    @Test
    void registrarTraduzConflitoDeIndiceUnicoParaRegraDeNegocio() {
        when(userRepository.findByEmail("ana@example.com")).thenReturn(Optional.empty());
        when(courierRepository.findByEmail("ana@example.com")).thenReturn(Optional.empty());
        when(passwordEncoder.encode("secret1")).thenReturn("encoded-password");
        when(userRepository.save(any(User.class))).thenThrow(new DuplicateKeyException("duplicate"));

        assertThatThrownBy(() -> service.register(new RegisterRequest(
                "Ana", "ana@example.com", "13999990000", "secret1", "CLIENT", null)))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessage("E-mail já cadastrado.");
    }

    @Test
    void loginAutenticaClienteAtivoComEmailNormalizado() {
        User user = new User();
        user.setId("user-1");
        user.setNome("Ana");
        user.setEmail("ana@example.com");
        user.setSenhaHash("encoded-password");
        user.setAtivo(true);
        when(jwtService.generateToken("user-1", "ana@example.com", "CLIENT")).thenReturn("jwt-token");
        when(userRepository.findByEmail("ana@example.com")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("secret1", "encoded-password")).thenReturn(true);

        AuthResponse response = service.login(new LoginRequest(" ANA@EXAMPLE.COM ", "secret1"));

        assertThat(response).isEqualTo(new AuthResponse("jwt-token", "user-1", "Ana", "CLIENT"));
        verify(jwtService).generateToken("user-1", "ana@example.com", "CLIENT");
        verify(courierRepository, never()).findByEmail(any());
    }

    @Test
    void loginRecusaClienteInativo() {
        User user = new User();
        user.setAtivo(false);
        when(userRepository.findByEmail("ana@example.com")).thenReturn(Optional.of(user));
        when(courierRepository.findByEmail("ana@example.com")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.login(new LoginRequest("ana@example.com", "secret1")))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessage("Credenciais inválidas.");

        verify(passwordEncoder, never()).matches(any(), any());
    }

    @Test
    void loginAutenticaEntregadorQuandoNaoHaCliente() {
        Courier courier = new Courier();
        courier.setId("courier-1");
        courier.setNome("Leo");
        courier.setSenhaHash("encoded-password");
        when(jwtService.generateToken("courier-1", "leo@example.com", "COURIER")).thenReturn("jwt-token");
        when(userRepository.findByEmail("leo@example.com")).thenReturn(Optional.empty());
        when(courierRepository.findByEmail("leo@example.com")).thenReturn(Optional.of(courier));
        when(passwordEncoder.matches("secret1", "encoded-password")).thenReturn(true);

        AuthResponse response = service.login(new LoginRequest("leo@example.com", "secret1"));

        assertThat(response).isEqualTo(new AuthResponse("jwt-token", "courier-1", "Leo", "COURIER"));
        verify(jwtService).generateToken("courier-1", "leo@example.com", "COURIER");
    }

    @Test
    void loginRecusaSenhaInvalida() {
        when(userRepository.findByEmail("ana@example.com")).thenReturn(Optional.empty());
        when(courierRepository.findByEmail("ana@example.com")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.login(new LoginRequest("ana@example.com", "wrong")))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessage("Credenciais inválidas.");
    }
}
