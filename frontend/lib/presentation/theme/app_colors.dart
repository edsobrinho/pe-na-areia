import 'package:flutter/material.dart';

/// Paleta oficial do Design System "Brisa Minimalista — Sage & Apricot"
/// extraída das 5 telas de referência (`food-delivery.psd`) e unificada em
/// todo o ecossistema Pé na Areia (Cliente, Entregador, Protótipos e Portal Web).
class AppColors {
  // ===========================================================================
  // 1. MARCA PRIMÁRIA — SAGE MINT (CTAs em Pílula, Seleção, Navegação e Rota)
  // ===========================================================================
  static const sage500 = Color(0xFF8BBFB0);
  static const sage600 = Color(0xFF6FA898);
  static const sage700 = Color(0xFF4F8A7A);
  static const sage300 = Color(0xFFADD3C8);
  static const sage200 = Color(0xFFA2CCC0);
  static const sage100 = Color(0xFFE8F3F0);

  // ===========================================================================
  // 2. DESTAQUE COMERCIAL & GEOLOCALIZAÇÃO — WARM APRICOT (Preços, Estrelas e Pins)
  // ===========================================================================
  static const apricot500 = Color(0xFFFF9749);
  static const apricot400 = Color(0xFFF59B56);
  static const apricot600 = Color(0xFFE07B2D);
  static const apricot100 = Color(0xFFFFF3E8);

  // ===========================================================================
  // 3. SUPERFÍCIES MINIMALISTAS CLARAS & NEUTROS
  // ===========================================================================
  static const canvas = Color(0xFFFAFAFA);
  static const background = Color(0xFFFAFAFA);
  static const surface = Color(0xFFFFFFFF);
  static const placeholder = Color(0xFFEAEEED);
  static const stepperBg = Color(0xFFF9FAFA);
  static const dragHandle = Color(0xFFE3E8E7);

  // ===========================================================================
  // 4. TIPOGRAFIA E BORDAS FINAS
  // ===========================================================================
  static const ink = Color(0xFF292728);
  static const ink700 = Color(0xFF4A504F);
  static const ink500 = Color(0xFF9DA5A3);
  static const ink400 = Color(0xFFB4BCBA);
  static const line = Color(0xFFEFEFEF);
  static const lineStrong = Color(0xFFDCE3E1);

  // ===========================================================================
  // 5. ESTADOS SEMÂNTICOS & SINALIZAÇÃO SOLAR
  // ===========================================================================
  static const positive = Color(0xFF6FA898);
  static const destination = Color(0xFFFF9749);
  static const sun400 = Color(0xFFFFD600);
  static const danger500 = Color(0xFFE05252);
  static const danger100 = Color(0xFFFEECEC);

  // ===========================================================================
  // 6. IDENTIDADE OFICIAL DO LOGO PÉ NA AREIA (GUARDA-SOL, SOL & AREIA)
  // ===========================================================================
  static const logoUmbrellaRed = Color(0xFFE52E2D);
  static const logoSun = Color(0xFFFFA500);
  static const logoSandMound = Color(0xFFE8D5B5);
  static const logoOceanDark = Color(0xFF0C383F);
  static const logoOceanText = Color(0xFF0B3B40);

  // ===========================================================================
  // ALIASES DE COMPATIBILIDADE SEMÂNTICA DO ECOSSISTEMA
  // ===========================================================================
  static const ocean900 = ink;
  static const ocean800 = sage700;
  static const ocean700 = sage500;
  static const ocean500 = sage600;
  static const ocean100 = sage100;

  static const coral600 = apricot600;
  static const coral500 = apricot500;
  static const coral100 = apricot100;
  static const mango500 = sage500;
  static const brandRed = sage500;

  static const sand50 = background;
  static const sand100 = placeholder;
  static const sand200 = line;

  static const seafoam700 = sage700;
  static const seafoam500 = sage600;
}
