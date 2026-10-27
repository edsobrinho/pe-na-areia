/**
 * Máscaras e formatadores para o ecossistema brasileiro.
 * Todas as funções garantem limpeza prévia e formatação incremental.
 */

/**
 * Remove qualquer caractere que não seja dígito numérico.
 */
export function unmask(value: string | null | undefined): string {
  if (!value) return ''
  return value.replace(/\D/g, '')
}

/**
 * Máscara para CPF: 000.000.000-00 (máximo 11 dígitos)
 */
export function maskCPF(value: string): string {
  const digits = unmask(value).slice(0, 11)
  return digits
    .replace(/^(\d{3})(\d)/, '$1.$2')
    .replace(/^(\d{3})\.(\d{3})(\d)/, '$1.$2.$3')
    .replace(/^(\d{3})\.(\d{3})\.(\d{3})(\d)/, '$1.$2.$3-$4')
}

/**
 * Máscara para CNPJ: 00.000.000/0000-00 (máximo 14 dígitos)
 */
export function maskCNPJ(value: string): string {
  const digits = unmask(value).slice(0, 14)
  return digits
    .replace(/^(\d{2})(\d)/, '$1.$2')
    .replace(/^(\d{2})\.(\d{3})(\d)/, '$1.$2.$3')
    .replace(/^(\d{2})\.(\d{3})\.(\d{3})(\d)/, '$1.$2.$3/$4')
    .replace(/^(\d{2})\.(\d{3})\.(\d{3})\/(\d{4})(\d)/, '$1.$2.$3/$4-$5')
}

/**
 * Máscara dinâmica para Telefone fixo (10 dígitos) ou Celular (11 dígitos):
 * (00) 0000-0000 ou (00) 00000-0000
 */
export function maskPhone(value: string): string {
  const digits = unmask(value).slice(0, 11)
  if (digits.length <= 10) {
    return digits
      .replace(/^(\d{2})(\d)/, '($1) $2')
      .replace(/^(\(\d{2}\)\s)(\d{4})(\d)/, '$1$2-$3')
  }
  return digits
    .replace(/^(\d{2})(\d)/, '($1) $2')
    .replace(/^(\(\d{2}\)\s)(\d{5})(\d)/, '$1$2-$3')
}

/**
 * Máscara para CEP: 00000-000 (8 dígitos)
 */
export function maskCEP(value: string): string {
  const digits = unmask(value).slice(0, 8)
  return digits.replace(/^(\d{5})(\d)/, '$1-$2')
}

/**
 * Máscara para Data: dd/mm/aaaa (8 dígitos)
 */
export function maskDate(value: string): string {
  const digits = unmask(value).slice(0, 8)
  return digits
    .replace(/^(\d{2})(\d)/, '$1/$2')
    .replace(/^(\d{2})\/(\d{2})(\d)/, '$1/$2/$3')
}

/**
 * Formata um valor numérico em centavos para a representação monetária BRL:
 * Exemplo: 1250 -> "R$ 12,50"
 */
export function formatCurrencyBRL(cents: number): string {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL',
  }).format(cents / 100)
}

/**
 * Converte uma entrada de texto formatada ou crua para o valor inteiro de centavos:
 * Exemplo: "R$ 12,50" -> 1250
 */
export function parseCurrencyInputToCents(rawInput: string): number {
  const digits = unmask(rawInput)
  return digits ? parseInt(digits, 10) : 0
}

