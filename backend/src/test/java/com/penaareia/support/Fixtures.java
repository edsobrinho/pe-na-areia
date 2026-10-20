package com.penaareia.support;

import com.penaareia.dto.CreateOrderRequest;
import com.penaareia.model.Kiosk;
import com.penaareia.model.Order;
import com.penaareia.model.PaymentMethod;
import com.penaareia.model.ReferencePoint;
import com.penaareia.model.User;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

/**
 * Dados de teste compartilhados pelos testes de servico e controller.
 * Mantem os ids e valores em um unico lugar para que total, GeoJSON e
 * contrato de resposta possam ser conferidos de forma consistente.
 */
public final class Fixtures {

    public static final String USER_ID = "u1";
    public static final String KIOSK_ID = "k1";
    public static final String POSTO_ID = "rp1";
    public static final double LATITUDE = -23.97;
    public static final double LONGITUDE = -46.324;

    public static final String MENU_ITEM_DISPONIVEL = "m1";
    public static final String MENU_ITEM_BARATO = "m2";
    public static final String MENU_ITEM_INDISPONIVEL = "m3";

    public static final BigDecimal PRECO_DISPONIVEL = new BigDecimal("12.50");
    public static final BigDecimal PRECO_BARATO = new BigDecimal("7.25");

    private Fixtures() {
    }

    public static User usuarioAtivo() {
        User user = new User();
        user.setId(USER_ID);
        user.setNome("Ana Souza");
        user.setEmail("ana@example.com");
        user.setTelefone("(13) 99999-0000");
        user.setAtivo(true);
        return user;
    }

    public static User usuarioInativo() {
        User user = usuarioAtivo();
        user.setAtivo(false);
        return user;
    }

    public static Kiosk kioskAtivo() {
        Kiosk kiosk = new Kiosk();
        kiosk.setId(KIOSK_ID);
        kiosk.setNome("Quiosque do Ze");
        kiosk.setPontoReferenciaId(POSTO_ID);
        kiosk.setLocalizacao(new GeoJsonPoint(-46.31, -23.96));
        kiosk.setAceitaEmbalagemSustentavel(true);
        kiosk.setAtivo(true);
        kiosk.setCardapio(new ArrayList<>(List.of(
                new Kiosk.MenuItem(MENU_ITEM_DISPONIVEL, "Agua de coco", "Coco verde gelado", PRECO_DISPONIVEL, true),
                new Kiosk.MenuItem(MENU_ITEM_BARATO, "Pao de queijo", "Porcao com 4 unidades", PRECO_BARATO, true),
                new Kiosk.MenuItem(MENU_ITEM_INDISPONIVEL, "Refrigerante", "Lata 350ml", new BigDecimal("4.00"), false)
        )));
        return kiosk;
    }

    public static Kiosk kioskInativo() {
        Kiosk kiosk = kioskAtivo();
        kiosk.setAtivo(false);
        return kiosk;
    }

    public static ReferencePoint postoAtivo() {
        ReferencePoint ponto = new ReferencePoint();
        ponto.setId(POSTO_ID);
        ponto.setNumero(6);
        ponto.setNome("Posto 6");
        ponto.setTrecho("Boqueirao");
        ponto.setLocalizacao(new GeoJsonPoint(-46.32, -23.97));
        ponto.setAtivo(true);
        return ponto;
    }

    public static ReferencePoint postoInativo() {
        ReferencePoint ponto = postoAtivo();
        ponto.setAtivo(false);
        return ponto;
    }

    /** Pedido valido: 2x Agua de coco (12.50) + 1x Pao de queijo (7.25) = 32.25. */
    public static CreateOrderRequest requestValido() {
        CreateOrderRequest request = new CreateOrderRequest();
        request.setUserId(USER_ID);
        request.setKioskId(KIOSK_ID);
        request.setItens(new ArrayList<>(List.of(item(MENU_ITEM_DISPONIVEL, 2), item(MENU_ITEM_BARATO, 1))));
        request.setFormaPagamento(PaymentMethod.PIX);
        request.setEmbalagemSustentavel(true);
        request.setPinCliente(pin(LATITUDE, LONGITUDE));
        request.setPontoReferenciaId(POSTO_ID);
        request.setDescricaoLocal("Guarda-sol listrado azul");
        return request;
    }

    public static CreateOrderRequest.ItemRequest item(String menuItemId, Integer quantidade) {
        CreateOrderRequest.ItemRequest item = new CreateOrderRequest.ItemRequest();
        item.setMenuItemId(menuItemId);
        item.setQuantidade(quantidade);
        return item;
    }

    public static CreateOrderRequest.PinClienteRequest pin(Double latitude, Double longitude) {
        CreateOrderRequest.PinClienteRequest pin = new CreateOrderRequest.PinClienteRequest();
        pin.setLatitude(latitude);
        pin.setLongitude(longitude);
        return pin;
    }

    /** Entidade Order completa, usada para testar o contrato de resposta (201). */
    public static Order orderEntity() {
        Order order = new Order();
        order.setId("o1");
        order.setUserId(USER_ID);
        order.setKioskId(KIOSK_ID);
        order.setCourierId(null);
        order.setItens(List.of(
                new Order.OrderItem(MENU_ITEM_DISPONIVEL, "Agua de coco", 2, PRECO_DISPONIVEL),
                new Order.OrderItem(MENU_ITEM_BARATO, "Pao de queijo", 1, PRECO_BARATO)
        ));
        order.setValorTotal(new BigDecimal("32.25"));
        order.setEmbalagemSustentavel(true);
        order.setFormaPagamento(PaymentMethod.PIX);
        order.setPago(false);
        // GeoJsonPoint espera (longitude, latitude), nessa ordem
        order.setPinCliente(new GeoJsonPoint(LONGITUDE, LATITUDE));
        order.setPontoReferenciaId(POSTO_ID);
        order.setDescricaoLocal("Guarda-sol listrado azul");
        order.setFotoLocalUrl("https://res.cloudinary.com/demo/image/upload/foto-local.png");
        order.transitionTo(com.penaareia.model.OrderStatus.PAGO);
        order.transitionTo(com.penaareia.model.OrderStatus.EM_PREPARO);
        return order;
    }
}
