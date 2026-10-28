import type { MenuItem } from '../../types'

export const COASTAL_CATEGORIES = [
  'Água de Coco',
  'Porções',
  'Frutos do Mar',
  'Pastéis',
  'Bebidas',
  'Cervejas & Drinks',
  'Açaí & Gelados',
  'Espetinhos',
  'Lanches',
  'Sobremesas',
  'Combos Guarda-Sol',
  'Outros',
] as const

interface CategoryTabsProps {
  items: MenuItem[]
  selectedCategory: string
  onSelectCategory: (category: string) => void
}

export function CategoryTabs({ items, selectedCategory, onSelectCategory }: CategoryTabsProps) {
  const counts = items.reduce<Record<string, number>>((acc, item) => {
    const cat = item.category || 'Outros'
    acc[cat] = (acc[cat] ?? 0) + 1
    return acc
  }, {})

  // Categorias que possuem itens + categorias padrão da orla
  const uniqueCategories = Array.from(
    new Set([...Object.keys(counts), ...COASTAL_CATEGORIES]),
  )

  return (
    <div
      className="chip-row"
      role="tablist"
      aria-label="Filtrar produtos por categoria"
      style={{ marginBottom: '1rem' }}
    >
      <button
        type="button"
        role="tab"
        aria-selected={selectedCategory === 'ALL'}
        className={`chip ${selectedCategory === 'ALL' ? 'active' : ''}`}
        onClick={() => onSelectCategory('ALL')}
      >
        Todas ({items.length})
      </button>
      {uniqueCategories.map((cat) => {
        const count = counts[cat] ?? 0
        return (
          <button
            key={cat}
            type="button"
            role="tab"
            aria-selected={selectedCategory === cat}
            className={`chip ${selectedCategory === cat ? 'active' : ''}`}
            onClick={() => onSelectCategory(cat)}
          >
            {cat} ({count})
          </button>
        )
      })}
    </div>
  )
}

