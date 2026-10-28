package com.penaareia.service;

import com.penaareia.model.Kiosk;
import com.penaareia.model.Partnership;
import com.penaareia.model.User;
import com.penaareia.repository.KioskRepository;
import com.penaareia.repository.PartnershipRepository;
import com.penaareia.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AdminServiceTest {

    @Mock
    private UserRepository userRepository;
    @Mock
    private KioskRepository kioskRepository;
    @Mock
    private PartnershipRepository partnershipRepository;

    @InjectMocks
    private AdminService service;

    @Test
    void assignsActiveNonAdminUserToExistingKiosk() {
        User user = new User();
        user.setEmail("operator@example.test");
        user.setAtivo(true);
        Kiosk kiosk = new Kiosk();
        when(userRepository.findByEmail("operator@example.test")).thenReturn(Optional.of(user));
        when(kioskRepository.findById("kiosk-1")).thenReturn(Optional.of(kiosk));
        when(userRepository.save(user)).thenReturn(user);

        User assigned = service.assignKioskOperator(" OPERATOR@example.test ", "kiosk-1");

        assertThat(assigned.getRole()).isEqualTo("KIOSK_OPERATOR");
        assertThat(assigned.getKioskId()).isEqualTo("kiosk-1");
        verify(userRepository).save(user);
    }

    @Test
    void rejectsUnknownUserOrKiosk() {
        when(userRepository.findByEmail("missing@example.test")).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.assignKioskOperator("missing@example.test", "kiosk-1"))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessage("Usuário não encontrado.");

        User user = new User();
        user.setAtivo(true);
        when(userRepository.findByEmail("user@example.test")).thenReturn(Optional.of(user));
        when(kioskRepository.findById("missing")).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.assignKioskOperator("user@example.test", "missing"))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessage("Quiosque não encontrado.");
    }

    @Test
    void rejectsInactiveUsersAndAdministrators() {
        User inactive = new User();
        inactive.setAtivo(false);
        when(userRepository.findByEmail("inactive@example.test")).thenReturn(Optional.of(inactive));
        when(kioskRepository.findById("kiosk-1")).thenReturn(Optional.of(new Kiosk()));
        assertThatThrownBy(() -> service.assignKioskOperator("inactive@example.test", "kiosk-1"))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessage("Não é possível atribuir um usuário inativo.");

        User admin = new User();
        admin.setAtivo(true);
        admin.setRole("ADMIN");
        when(userRepository.findByEmail("admin@example.test")).thenReturn(Optional.of(admin));
        assertThatThrownBy(() -> service.assignKioskOperator("admin@example.test", "kiosk-1"))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessage("Uma conta de administrador não pode ser convertida em operador.");
    }

    @Test
    void createsTrimmedActivePartnership() {
        when(partnershipRepository.save(org.mockito.ArgumentMatchers.any(Partnership.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        Partnership created = service.createPartnership("  Canal  ", "  APP  ");

        assertThat(created.getName()).isEqualTo("Canal");
        assertThat(created.getChannel()).isEqualTo("APP");
        assertThat(created.isActive()).isTrue();
    }

    @Test
    void changesPartnershipActivityOrRejectsUnknownPartnership() {
        Partnership partnership = new Partnership("p-1", "Canal", "APP", true);
        when(partnershipRepository.findById("p-1")).thenReturn(Optional.of(partnership));
        when(partnershipRepository.save(partnership)).thenReturn(partnership);
        assertThat(service.setPartnershipActive("p-1", false).isActive()).isFalse();

        when(partnershipRepository.findById("missing")).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.setPartnershipActive("missing", true))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessage("Parceria não encontrada.");
    }
}
