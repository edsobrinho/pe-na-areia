import { z } from 'zod'
import { unmask } from './masks.ts'

/**
 * Expressões regulares ancoradas exclusivas para formato sintático.
 */

// Formato CPF: 000.000.000-00
export const REGEX_CPF_FORMAT = /^\d{3}\.\d{3}\.\d{3}-\d{2}$/

// Formato CNPJ: 00.000.000/0000-00
export const REGEX_CNPJ_FORMAT = /^\d{2}\.\d{3}\.\d{3}\/\d{4}-\d{2}$/

// Formato Telefone com DDD: (XX) XXXX-XXXX ou (XX) 9XXXX-XXXX
export const REGEX_PHONE_FORMAT = /^\(\d{2}\)\s\d{4,5}-\d{4}$/

// Formato CEP: XXXXX-XXX
export const REGEX_CEP_FORMAT = /^\d{5}-\d{3}$/

// Formato Data: DD/MM/AAAA
export const REGEX_DATE_FORMAT = /^\d{2}\/\d{2}\/\d{4}$/

// Formato E-mail padrão RFC simplificado (sem espaços)
export const REGEX_EMAIL_FORMAT = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/

/**
 * Validação matemática do CPF (Módulo 11 com 2 dígitos verificadores).
 */
export function isValidCPF(rawCpf: string | null | undefined): boolean {
  const digits = unmask(rawCpf)
  if (digits.length !== 11) return false
  if (/^(\d)\1{10}$/.test(digits)) return false // Rejeita sequências de dígitos iguais

  let sum = 0
  for (let i = 0; i < 9; i++) {
    sum += parseInt(digits[i], 10) * (10 - i)
  }
  let remainder = (sum * 10) % 11
  const d1 = remainder === 10 || remainder === 11 ? 0 : remainder
  if (d1 !== parseInt(digits[9], 10)) return false

  sum = 0
  for (let i = 0; i < 10; i++) {
    sum += parseInt(digits[i], 10) * (11 - i)
  }
  remainder = (sum * 10) % 11
  const d2 = remainder === 10 || remainder === 11 ? 0 : remainder
  return d2 === parseInt(digits[10], 10)
}

/**
 * Validação do CNPJ com pesos oficiais da Receita Federal.
 */
export function isValidCNPJ(rawCnpj: string | null | undefined): boolean {
  const digits = unmask(rawCnpj)
  if (digits.length !== 14) return false
  if (/^(\d)\1{13}$/.test(digits)) return false

  const weights1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
  let sum = 0
  for (let i = 0; i < 12; i++) {
    sum += parseInt(digits[i], 10) * weights1[i]
  }
  let rem = sum % 11
  const d1 = rem < 2 ? 0 : 11 - rem
  if (d1 !== parseInt(digits[12], 10)) return false

  const weights2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
  sum = 0
  for (let i = 0; i < 13; i++) {
    sum += parseInt(digits[i], 10) * weights2[i]
  }
  rem = sum % 11
  const d2 = rem < 2 ? 0 : 11 - rem
  return d2 === parseInt(digits[13], 10)
}

/**
 * Validação de telefone brasileiro (DDD entre 11 e 99 e 9º dígito para celular de 11 dígitos).
 */
export function isValidPhoneBR(rawPhone: string | null | undefined): boolean {
  const digits = unmask(rawPhone)
  if (digits.length !== 10 && digits.length !== 11) return false

  const ddd = parseInt(digits.slice(0, 2), 10)
  if (ddd < 11 || ddd > 99) return false

  // Se tem 11 dígitos (celular móvel), o 3º dígito deve ser 9
  if (digits.length === 11 && digits[2] !== '9') {
    return false
  }
  return true
}

/**
 * Validação de CEP brasileiro (8 dígitos, diferente de 00000-000).
 */
export function isValidCEP(rawCep: string | null | undefined): boolean {
  const digits = unmask(rawCep)
  if (digits.length !== 8) return false
  if (digits === '00000000') return false
  return true
}

/**
 * Validação de data no formato dd/mm/aaaa com calendário real, anos bissextos e limite de idade opcional.
 */
export function isValidDateBR(dateStr: string | null | undefined, minAge = 0, maxAge = 120): boolean {
  if (!dateStr || !REGEX_DATE_FORMAT.test(dateStr)) return false
  const [dayStr, monthStr, yearStr] = dateStr.split('/')
  const day = parseInt(dayStr, 10)
  const month = parseInt(monthStr, 10)
  const year = parseInt(yearStr, 10)

  if (month < 1 || month > 12) return false

  const isLeap = (year % 4 === 0 && year % 100 !== 0) || year % 400 === 0
  const daysInMonth = [31, isLeap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  if (day < 1 || day > daysInMonth[month - 1]) return false

  const parsedDate = new Date(year, month - 1, day)
  const today = new Date()
  if (parsedDate > today) return false

  if (minAge > 0 || maxAge < 120) {
    let age = today.getFullYear() - parsedDate.getFullYear()
    const m = today.getMonth() - parsedDate.getMonth()
    if (m < 0 || (m === 0 && today.getDate() < parsedDate.getDate())) {
      age--
    }
    if (age < minAge || age > maxAge) return false
  }

  return true
}

/**
 * Validação de e-mail com higienização prévia.
 */
export function isValidEmail(email: string | null | undefined): boolean {
  if (!email) return false
  return REGEX_EMAIL_FORMAT.test(email.trim().toLowerCase())
}

/**
 * Schemas do Zod para formulários reativos.
 */
export const clientRegistrationSchema = z.object({
  fullName: z
    .string()
    .trim()
    .min(3, 'O nome deve ter no mínimo 3 caracteres')
    .refine((val) => val.split(/\s+/).filter(Boolean).length >= 2, {
      message: 'Informe o nome e ao menos um sobrenome',
    }),

  email: z
    .string()
    .trim()
    .toLowerCase()
    .regex(REGEX_EMAIL_FORMAT, 'E-mail em formato inválido (exemplo: usuario@email.com)'),

  phone: z
    .string()
    .regex(REGEX_PHONE_FORMAT, 'Formato deve ser (XX) 9XXXX-XXXX')
    .refine(isValidPhoneBR, 'DDD ou número de telefone inválido')
    .transform(unmask),

  cpf: z
    .string()
    .regex(REGEX_CPF_FORMAT, 'Formato deve ser 000.000.000-00')
    .refine(isValidCPF, 'CPF inválido. Verifique os números digitados')
    .transform(unmask),

  birthDate: z
    .string()
    .refine((val) => isValidDateBR(val, 18), {
      message: 'Data inválida ou você deve ser maior de 18 anos',
    })
    .transform((val) => {
      const [d, m, y] = val.split('/')
      return `${y}-${m}-${d}`
    }),

  cep: z
    .string()
    .regex(REGEX_CEP_FORMAT, 'CEP deve conter 8 dígitos no formato 00000-000')
    .transform(unmask),

  declaredIncomeCents: z
    .number()
    .min(100, 'O valor mínimo é de R$ 1,00'),
})

export type ClientRegistrationFormData = z.input<typeof clientRegistrationSchema>
export type ClientRegistrationApiPayload = z.output<typeof clientRegistrationSchema>
