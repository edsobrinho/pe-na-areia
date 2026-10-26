package com.penaareia.repository;

import com.penaareia.model.KioskPartnership;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;
import java.util.Optional;

public interface KioskPartnershipRepository extends MongoRepository<KioskPartnership, String> {

    Optional<KioskPartnership> findByKioskIdAndPartnershipId(String kioskId, String partnershipId);

    List<KioskPartnership> findByKioskId(String kioskId);

    List<KioskPartnership> findByPartnershipIdAndActiveTrue(String partnershipId);
}
