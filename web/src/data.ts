export type OrderStatus = 'Новый' | 'Курьер назначен' | 'В пути' | 'Задержка' | 'Доставлен' | 'Отменён'

export type Order = {
  apiId?: string
  pickupLatitude?: number
  pickupLongitude?: number
  deliveryLatitude?: number
  deliveryLongitude?: number
  id: number
  client: string
  pickup: string
  destination: string
  courier: string
  vehicle: string
  eta: string
  status: OrderStatus
  price: number
  created: string
  note: string
  progress: number
}

export const orders: Order[] = [
  { id: 1048, client: 'Мердан А.', pickup: 'ул. А. Навои, 17', destination: 'ТЦ «Беркарар»', courier: 'Бегенч Оразов', vehicle: 'Skoda Rapid · 83-41', eta: '8 мин', status: 'В пути', price: 68, created: '10:24', note: 'Документы, передать лично в руки', progress: 66 },
  { id: 1047, client: 'Ayna Studio', pickup: 'Битараплык, 95', destination: 'ул. Героглы, 44', courier: 'Не назначен', vehicle: '—', eta: 'Нужен курьер', status: 'Новый', price: 92, created: '10:18', note: 'Хрупкое. Коробка 40 × 30 см', progress: 8 },
  { id: 1046, client: 'Гульшат Б.', pickup: 'мкр. Мир 7, дом 12', destination: 'ул. 10 йыл Абаданчылык', courier: 'Мурад Сапаров', vehicle: 'Toyota Corolla · 01-92', eta: '17 мин', status: 'Курьер назначен', price: 74, created: '10:04', note: 'Позвонить получателю через внутреннюю связь', progress: 32 },
  { id: 1045, client: 'Ojak Market', pickup: 'ул. Анкара, 61', destination: 'мкр. Парахат 7/4', courier: 'Ровшен Нуров', vehicle: 'Скутер · 22-08', eta: '+12 мин', status: 'Задержка', price: 55, created: '09:48', note: 'Клиент предупрежден о задержке', progress: 78 },
  { id: 1044, client: 'Алтын Г.', pickup: 'ТЦ «Ашхабад»', destination: 'ул. Кемине, 128', courier: 'Довлет Ходжаев', vehicle: 'Skoda Rapid · 04-17', eta: '3 мин', status: 'В пути', price: 61, created: '09:41', note: 'Оставить на ресепшене', progress: 90 },
  { id: 1043, client: 'Nur Coffee', pickup: 'пр. Махтумкули, 73', destination: 'БЦ «Аркач»', courier: 'Шатлык Язов', vehicle: 'Велосипед', eta: '11 мин', status: 'В пути', price: 38, created: '09:32', note: 'Термосумка обязательна', progress: 57 },
]

export const couriers = [
  { name: 'Бегенч Оразов', initials: 'БО', orders: 2, zone: 'Центр', status: 'В пути', tone: 'mint' },
  { name: 'Мурад Сапаров', initials: 'МС', orders: 1, zone: 'Копетдаг', status: 'На месте', tone: 'blue' },
  { name: 'Ровшен Нуров', initials: 'РН', orders: 2, zone: 'Парахат', status: 'Задержка', tone: 'orange' },
  { name: 'Довлет Ходжаев', initials: 'ДХ', orders: 1, zone: 'Центр', status: 'Свободен через 5 мин', tone: 'violet' },
]
