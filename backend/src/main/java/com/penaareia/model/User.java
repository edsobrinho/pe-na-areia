package com.penaareia.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "users")
public class User {

    @Id
    private String id;

    private String nome;

    @Indexed(unique = true)
    private String email;

    private String telefone;

    /** Hash da senha - nunca armazenar em texto puro */
    private String senhaHash;

    /** Usuarios inativos nao podem criar novos pedidos */
    private boolean ativo = true;

    private Instant criadoEm = Instant.now();
}
