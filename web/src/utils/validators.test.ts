import { describe, it } from 'node:test'
import assert from 'node:assert/strict'
import {
  isValidCPF,
  isValidCNPJ,
  isValidPhoneBR,
  isValidCEP,
  isValidDateBR,
  isValidEmail,
  REGEX_CPF_FORMAT,
  REGEX_CNPJ_FORMAT,
  REGEX_PHONE_FORMAT,
  REGEX_CEP_FORMAT,
  REGEX_DATE_FORMAT,
} from './validators.ts'
import {
  maskCPF,
  maskCNPJ,
  maskPhone,
  maskCEP,
  maskDate,
  unmask,
  formatCurrencyBRL,
  parseCurrencyInputToCents,
} from './masks.ts'

describe('Utilitários de Máscaras e Formatação (masks.ts)', () => {
  // Identificadores fictícios com dígitos verificadores calculados para testes.
  it('unmask remove todos os caracteres não numéricos', () => {
    assert.equal(unmask('123.456.789-00'), '12345678900')
    assert.equal(unmask('(13) 99712-3456'), '13997123456')
    assert.equal(unmask(''), '')
  })

  it('maskCPF formata progressivamente até 11 dígitos', () => {
    assert.equal(maskCPF('98765432100'), '987.654.321-00')
    assert.equal(maskCPF('987654'), '987.654')
  })

  it('maskCNPJ formata progressivamente até 14 dígitos', () => {
    assert.equal(maskCNPJ('12345678000195'), '12.345.678/0001-95')
  })

  it('maskPhone formata fixo (10 dígitos) e celular (11 dígitos)', () => {
    assert.equal(maskPhone('1332191000'), '(13) 3219-1000')
    assert.equal(maskPhone('13997123456'), '(13) 99712-3456')
  })

  it('maskCEP formata 8 dígitos', () => {
    assert.equal(maskCEP('11055300'), '11055-300')
  })

  it('maskDate formata 8 dígitos no padrão dd/mm/aaaa', () => {
    assert.equal(maskDate('27102026'), '27/10/2026')
  })

  it('formatCurrencyBRL e parseCurrencyInputToCents manipulam centavos corretamente', () => {
    assert.equal(parseCurrencyInputToCents('R$ 25,50'), 2550)
    assert.ok(formatCurrencyBRL(2550).includes('25,50'))
  })
})

describe('Validadores de Negócio Brasileiros (validators.ts)', () => {
  // Identificadores fictícios com dígitos verificadores calculados para testes.
  describe('Validação de CPF', () => {
    it('deve aceitar CPFs válidos com e sem máscara', () => {
      assert.equal(isValidCPF('98765432100'), true)
      assert.equal(isValidCPF('987.654.321-00'), true)
    })

    it('deve rejeitar sequências de dígitos iguais', () => {
      assert.equal(isValidCPF('111.111.111-11'), false)
      assert.equal(isValidCPF('000.000.000-00'), false)
      assert.equal(isValidCPF('999.999.999-99'), false)
    })

    it('deve rejeitar CPFs com dígitos verificadores inválidos', () => {
      assert.equal(isValidCPF('987.654.321-01'), false)
    })

    it('deve validar regex de formato', () => {
      assert.equal(REGEX_CPF_FORMAT.test('987.654.321-00'), true)
      assert.equal(REGEX_CPF_FORMAT.test('98765432100'), false)
    })
  })

  describe('Validação de CNPJ', () => {
    it('deve aceitar CNPJ válido', () => {
      assert.equal(isValidCNPJ('12.345.678/0001-95'), true)
      assert.equal(isValidCNPJ('12345678000195'), true)
    })

    it('deve rejeitar sequências iguais e dígitos falsos', () => {
      assert.equal(isValidCNPJ('00.000.000/0000-00'), false)
      assert.equal(isValidCNPJ('11.111.111/1111-11'), false)
      assert.equal(isValidCNPJ('12.345.678/0001-96'), false)
    })

    it('deve validar regex de formato', () => {
      assert.equal(REGEX_CNPJ_FORMAT.test('12.345.678/0001-95'), true)
      assert.equal(REGEX_CNPJ_FORMAT.test('12345678000195'), false)
    })
  })

  describe('Validação de Telefone / Celular', () => {
    it('deve aceitar celular válido de 11 dígitos com 9º dígito', () => {
      assert.equal(isValidPhoneBR('(13) 99712-3456'), true)
      assert.equal(REGEX_PHONE_FORMAT.test('(13) 99712-3456'), true)
    })

    it('deve aceitar telefone fixo válido de 10 dígitos', () => {
      assert.equal(isValidPhoneBR('(13) 3219-1000'), true)
      assert.equal(REGEX_PHONE_FORMAT.test('(13) 3219-1000'), true)
    })

    it('deve rejeitar celular de 11 dígitos com terceiro dígito diferente de 9', () => {
      assert.equal(isValidPhoneBR('(13) 89712-3456'), false)
    })

    it('deve rejeitar DDDs inválidos fora da faixa 11..99', () => {
      assert.equal(isValidPhoneBR('(01) 99712-3456'), false)
      assert.equal(isValidPhoneBR('(00) 99712-3456'), false)
    })
  })

  describe('Validação de CEP', () => {
    it('deve validar CEP com 8 dígitos', () => {
      assert.equal(isValidCEP('11055-300'), true)
      assert.equal(REGEX_CEP_FORMAT.test('11055-300'), true)
    })

    it('deve rejeitar CEP nulo ou zerado', () => {
      assert.equal(isValidCEP('00000-000'), false)
      assert.equal(isValidCEP('1105'), false)
    })
  })

  describe('Validação de Datas e Bissextos', () => {
    it('deve validar anos bissextos (29/02/2024)', () => {
      assert.equal(isValidDateBR('29/02/2024'), true)
      assert.equal(REGEX_DATE_FORMAT.test('29/02/2024'), true)
    })

    it('deve rejeitar 29/02 em anos comuns (29/02/2023)', () => {
      assert.equal(isValidDateBR('29/02/2023'), false)
    })

    it('deve rejeitar datas no futuro', () => {
      assert.equal(isValidDateBR('01/01/2099'), false)
    })

    it('deve validar regra de idade mínima (ex: 18 anos)', () => {
      assert.equal(isValidDateBR('15/05/1990', 18), true)
      assert.equal(isValidDateBR('15/05/2020', 18), false)
    })
  })

  describe('Validação de E-mail', () => {
    it('deve validar e-mails com sintaxe correta', () => {
      assert.equal(isValidEmail('usuario@dominio.com.br'), true)
      assert.equal(isValidEmail('contato.cliente@gmail.com'), true)
    })

    it('deve rejeitar e-mails sem domínio, sem arroba ou com espaços', () => {
      assert.equal(isValidEmail('invalido@'), false)
      assert.equal(isValidEmail('usuario com espaco@dominio.com'), false)
      assert.equal(isValidEmail(''), false)
    })
  })
})
