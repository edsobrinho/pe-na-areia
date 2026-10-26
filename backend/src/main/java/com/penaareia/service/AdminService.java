package com.penaareia.service;

import com.penaareia.model.Kiosk;
import com.penaareia.model.Partnership;
import com.penaareia.model.User;
import com.penaareia.repository.KioskRepository;
import com.penaareia.repository.PartnershipRepository;
import com.penaareia.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AdminService {

    private final UserRepository userRepository;
    private final KioskRepository kioskRepository;
    private final PartnershipRepository partnershipRepository;

    public User assignKioskOperator(String email, String kioskId) {
        User user = userRepository.findByEmail(email.trim().toLowerCase(java.util.Locale.ROOT))
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado."));
        kioskRepository.findById(kioskId)
                .orElseThrow(() -> new ResourceNotFoundException("Quiosque não encontrado."));
        if (!user.isAtivo()) {
            throw new BusinessRuleException("Não é possível atribuir um usuário inativo.");
        }
        if ("ADMIN".equals(user.getRole())) {
            throw new BusinessRuleException("Uma conta de administrador não pode ser convertida em operador.");
        }
        user.setRole("KIOSK_OPERATOR");
        user.setKioskId(kioskId);
        return userRepository.save(user);
    }

    public Partnership createPartnership(String name, String channel) {
        Partnership partnership = new Partnership();
        partnership.setName(name.trim());
        partnership.setChannel(channel.trim());
        partnership.setActive(true);
        return partnershipRepository.save(partnership);
    }

    public Partnership setPartnershipActive(String partnershipId, boolean active) {
        Partnership partnership = partnershipRepository.findById(partnershipId)
                .orElseThrow(() -> new ResourceNotFoundException("Parceria não encontrada."));
        partnership.setActive(active);
        return partnershipRepository.save(partnership);
    }
}
