import { useEffect, useRef, useState } from 'react'
import { importLibrary, setOptions } from '@googlemaps/js-api-loader'
import type { ReferencePoint } from './types'

interface Props {
  points: ReferencePoint[]
  onChange: (latitude: number, longitude: number, referencePointId: string) => void
}

interface Coordinates {
  latitude: number
  longitude: number
}

const mapKey = import.meta.env.VITE_GOOGLE_MAPS_API_KEY as string | undefined
let mapsLibrary: Promise<google.maps.MapsLibrary> | null = null

function nearestReferencePoint(points: ReferencePoint[], position: Coordinates): ReferencePoint | undefined {
  return [...points].sort((left, right) =>
    distanceMeters(left, position) - distanceMeters(right, position),
  )[0]
}

function distanceMeters(point: ReferencePoint, position: Coordinates): number {
  const [longitude, latitude] = point.localizacao.coordinates
  const latitudeDelta = ((latitude - position.latitude) * Math.PI) / 180
  const longitudeDelta = ((longitude - position.longitude) * Math.PI) / 180
  const haversine =
    Math.sin(latitudeDelta / 2) ** 2 +
    Math.cos((position.latitude * Math.PI) / 180) *
      Math.cos((latitude * Math.PI) / 180) *
      Math.sin(longitudeDelta / 2) ** 2
  return 6_371_000 * 2 * Math.atan2(Math.sqrt(haversine), Math.sqrt(1 - haversine))
}

async function loadMaps(): Promise<google.maps.MapsLibrary> {
  if (!mapsLibrary) {
    setOptions({ key: mapKey ?? '', v: 'weekly' })
    mapsLibrary = importLibrary('maps') as Promise<google.maps.MapsLibrary>
  }
  return mapsLibrary
}

export function MapPicker({ points, onChange }: Props) {
  const mapElement = useRef<HTMLDivElement>(null)
  const marker = useRef<google.maps.Marker | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let disposed = false
    if (!mapKey || !mapElement.current) return
    void loadMaps()
      .then(({ Map }) => {
        if (disposed || !mapElement.current) return
        const center = { lat: -23.9722, lng: -46.328 }
        const map = new Map(mapElement.current, {
          center,
          zoom: 15,
          mapTypeControl: false,
          streetViewControl: false,
          fullscreenControl: false,
        })
        marker.current = new google.maps.Marker({ map, position: center, draggable: true })
        const update = (latitude: number, longitude: number) => {
          const position = { latitude, longitude }
          const reference = nearestReferencePoint(points, position)
          if (reference) onChange(latitude, longitude, reference.id)
          marker.current?.setPosition({ lat: latitude, lng: longitude })
        }
        map.addListener('click', (event: google.maps.MapMouseEvent) => {
          if (event.latLng) update(event.latLng.lat(), event.latLng.lng())
        })
        marker.current.addListener('dragend', () => {
          const position = marker.current?.getPosition()
          if (position) update(position.lat(), position.lng())
        })
      })
      .catch(() => {
        if (!disposed) setError('Não foi possível carregar o Google Maps. Verifique a chave e os serviços habilitados.')
      })
    return () => {
      disposed = true
      marker.current?.setMap(null)
      marker.current = null
    }
  }, [points, onChange])

  if (!mapKey) {
    return (
      <div className="map-message" role="status">
        Configure VITE_GOOGLE_MAPS_API_KEY para habilitar a seleção do pin. Sem o mapa, não é possível concluir
        um pedido pelo site.
      </div>
    )
  }

  return (
    <div>
      {error && <p className="field-error" role="alert">{error}</p>}
      <div ref={mapElement} className="map-canvas" aria-label="Mapa para escolher o ponto de entrega" />
      <p className="muted">Toque no mapa ou arraste o marcador para indicar seu local na praia.</p>
    </div>
  )
}
