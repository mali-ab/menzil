import { useEffect, useMemo, useRef, useState, type FormEvent } from 'react'
import {
  AlertTriangle, ArrowRight, Bell, Bike, Box, Car, Check, ChevronDown, ChevronRight,
  Command, LayoutDashboard, LocateFixed,
  Map, Menu, MessageSquareText, MoreHorizontal, Navigation, PackageCheck,
  LogOut, Phone, Plus, Search, SlidersHorizontal,
  Footprints, Truck, UsersRound, X, Zap,
} from 'lucide-react'
import { type Order, type OrderStatus } from './data'
import logo from '../assets/launcher_icon.png'
import {
  assignAdminCourier, clearSession, createAdminOrder, getAdminCouriers, getAdminOrders, getAdminOverview,
  login, saveSession, sendOrderMessage, setAdminCourierAvailability, setAdminOrderStatus, startOrderCall,
  type AdminCourier, type AdminOrder, type AdminOverview, type CreateAdminOrder,
} from './api'

type Language = 'ru' | 'tk'
const tk: Record<string, string> = {
  'Диспетчерская': 'Dispetçer merkezi', 'Заказы': 'Sargytlar', 'Курьеры': 'Kurýerler',
  'Все заказы': 'Ähli sargytlar', 'Новый заказ': 'Täze sargyt', 'Активные заказы': 'Işjeň sargytlar',
  'Курьеры на линии': 'Işdäki kurýerler', 'Доставлено сегодня': 'Şu gün eltilen', 'Требуют внимания': 'Üns talap edýär',
  'Заказы в работе': 'Işdäki sargytlar', 'Обновлено только что': 'Täzelendi',
  'Все': 'Ählisi', 'Новый': 'Täze', 'Курьер назначен': 'Kurýer bellenildi', 'В пути': 'Ýolda', 'Доставлен': 'Eltildi', 'Отменён': 'Ýatyryldy',
  'Заказ': 'Sargyt', 'Маршрут': 'Ugury', 'Курьер': 'Kurýer', 'Статус': 'Ýagdaý',
  'Команда курьеров': 'Kurýerler topary', 'Всего курьеров': 'Jemi kurýer', 'Сейчас на линии': 'Häzir işde',
  'Активных доставок': 'Işjeň eltip bermeler', 'Карта команды': 'Toparyň kartasy', 'Открыть': 'Açmak',
  'На линии': 'Işde', 'Не доступен': 'Elýeterli däl', 'Ничего не найдено': 'Hiç zat tapylmady',
  'Фильтры': 'Süzgüçler', 'Без курьера': 'Kurýersiz', 'Сбросить': 'Arassalamak',
  'Войти снова': 'Täzeden girmek', 'Повторить': 'Gaýtadan synanyşmak',
  'Операционный центр': 'Operasion merkez', 'Диспетчер': 'Dispetçer', 'Выйти': 'Çykmak',
  'Вход в диспетчерскую': 'Dispetçer merkezine giriş', 'Подключение к Menzil API': 'Menzil API bilen birikme',
  'Телефон': 'Telefon', 'Пароль': 'Açar söz', 'Подключение…': 'Birikdirilýär…', 'Войти': 'Girmek',
  'Не назначен': 'Bellenilmedi', 'Готово': 'Taýýar', 'В работе': 'Işlenilýär', 'Задержка': 'Gijikme',
  'Попробуйте изменить фильтр или запрос': 'Süzgüji ýa-da gözleg sözüni üýtgedip görüň',
  'Координаты недоступны': 'Koordinatlar elýeterli däl', 'Откуда': 'Nireden', 'Куда': 'Nirä',
  'Прогресс доставки': 'Eltip bermegiň gidişi', 'Заказ принят': 'Sargyt kabul edildi',
  'Курьер забрал отправление': 'Kurýer ugratmany aldy', 'Ожидается': 'Garaşylýar',
  'Доставка получателю': 'Alyja eltip bermek', 'Комментарий': 'Bellik',
  'Назначить курьера': 'Kurýer bellemek', 'Выберите курьера': 'Kurýeri saýlaň',
  'К точке': 'Aljak nokadyna', 'Отменить': 'Ýatyrmak', 'Написать': 'Hat ýazmak',
  'Следующий статус': 'Indiki ýagdaý', 'Сначала назначьте курьера': 'Ilki kurýer belläň',
  'НОВЫЙ ЗАКАЗ': 'TÄZE SARGYT', 'Создать доставку': 'Eltip bermäni döretmek',
  'Телефон клиента': 'Müşderiniň telefony', 'Название': 'Ady', 'Адрес отправления': 'Aljak salgysy',
  'Адрес получателя': 'Eltip beriljek salgy', 'Телефон получателя': 'Alyjynyň telefony',
  'Транспорт': 'Ulag', 'Пешком': 'Pyýada', 'Велосипед': 'Welosiped', 'Скутер': 'Skuter',
  'Автомобиль': 'Awtoulag', 'Грузовик': 'Ýük ulagy', 'Стоимость, TMT': 'Bahasy, TMT',
  'Отмена': 'Ýatyrmak', 'Создание…': 'Döredilýär…', 'Создать заказ': 'Sargyt döretmek',
  'Быстрые фильтры': 'Çalt süzgüçler', 'Центр': 'Merkez', 'Данные API в реальном времени': 'API maglumatlary hakyky wagtda',
  'На карте': 'Kartada', 'Все курьеры': 'Ähli kurýerler', 'Изменить доступность': 'Elýeterliligi üýtgetmek',
  'Закрыть меню': 'Menýuny ýapmak', 'Уведомления': 'Bildirişler', 'Позвонить': 'Jaň etmek',
}
const tr = (language: Language, text: string) => language === 'tk' ? (tk[text] || text) : text
const transportLabels: Record<string, [string, string]> = {
  foot: ['Пешком', 'Pyýada'], bicycle: ['Велосипед', 'Welosiped'], scooter: ['Скутер', 'Skuter'],
  car: ['Автомобиль', 'Awtoulag'], truck: ['Грузовик', 'Ýük ulagy'],
}
const transportName = (language: Language, value: string) => transportLabels[value]?.[language === 'tk' ? 1 : 0] || value
const transportIcon = (value: string) => value === 'foot' ? Footprints : value === 'bicycle' || value === 'scooter' ? Bike : value === 'car' ? Car : Truck
function TransportLabel({ language, value }: { language: Language; value: string }) {
  const Icon = transportIcon(value)
  return <span className="transport-label" style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}><Icon size={13} />{transportName(language, value)}</span>
}

const statusClass: Record<OrderStatus, string> = {
  'Новый': 'new', 'Курьер назначен': 'assigned', 'В пути': 'moving', 'Задержка': 'late', 'Доставлен': 'moving', 'Отменён': 'late',
}

const statusLabels: Record<string, OrderStatus> = { created: 'Новый', accepted: 'Курьер назначен', to_pickup: 'Курьер назначен', delivering: 'В пути', delivered: 'Доставлен', cancelled: 'Отменён' }

function fromApiOrder(order: AdminOrder): Order {
  const status = statusLabels[order.status] || 'Новый'
  return { apiId: order.id, id: order.public_number, client: order.client, pickup: order.pickup_address, destination: order.delivery_address, pickupLatitude: order.pickup_latitude, pickupLongitude: order.pickup_longitude, deliveryLatitude: order.delivery_latitude, deliveryLongitude: order.delivery_longitude, courier: order.courier || 'Не назначен', vehicle: order.transport, eta: status === 'Доставлен' ? 'Готово' : status === 'Отменён' ? 'Отменён' : 'В работе', status, price: order.price, created: new Date(order.created_at).toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit' }), note: order.description || order.title, progress: status === 'Новый' ? 8 : status === 'Курьер назначен' ? 32 : status === 'В пути' ? 66 : status === 'Доставлен' ? 100 : 0 }
}

function OpenStreetMap({ latitude, longitude, label }: { latitude: number; longitude: number; label: string }) {
  const pad = 0.012
  const bbox = `${longitude - pad},${latitude - pad},${longitude + pad},${latitude + pad}`
  const src = `https://www.openstreetmap.org/export/embed.html?bbox=${encodeURIComponent(bbox)}&layer=mapnik&marker=${latitude}%2C${longitude}`
  return <iframe title={`OpenStreetMap: ${label}`} src={src} loading="lazy" referrerPolicy="no-referrer-when-downgrade" />
}

function CouriersMap({ couriers, language }: { couriers: AdminCourier[]; language: Language }) {
  const mapRef = useRef<HTMLDivElement>(null)
  const [size, setSize] = useState({ width: 420, height: 330 })
  useEffect(() => {
    if (!mapRef.current) return
    const observer = new ResizeObserver(([entry]) => setSize({ width: entry.contentRect.width, height: entry.contentRect.height }))
    observer.observe(mapRef.current)
    return () => observer.disconnect()
  }, [])
  const located = couriers.filter((courier): courier is AdminCourier & { latitude: number; longitude: number } => courier.latitude != null && courier.longitude != null)
  const rawSouth = located.length ? Math.min(...located.map(courier => courier.latitude)) : 37.928
  const rawNorth = located.length ? Math.max(...located.map(courier => courier.latitude)) : 37.952
  const rawWest = located.length ? Math.min(...located.map(courier => courier.longitude)) : 58.368
  const rawEast = located.length ? Math.max(...located.map(courier => courier.longitude)) : 58.392
  const latitudePadding = Math.max((rawNorth - rawSouth) * 0.2, 0.006)
  const longitudePadding = Math.max((rawEast - rawWest) * 0.2, 0.006)
  const south = rawSouth - latitudePadding
  const north = rawNorth + latitudePadding
  const west = rawWest - longitudePadding
  const east = rawEast + longitudePadding
  const project = (latitude: number, longitude: number, zoom: number) => {
    const scale = 256 * 2 ** zoom
    const sin = Math.sin(latitude * Math.PI / 180)
    return { x: (longitude + 180) / 360 * scale, y: (0.5 - Math.log((1 + sin) / (1 - sin)) / (4 * Math.PI)) * scale }
  }
  let zoom = 14
  for (let candidate = 18; candidate >= 2; candidate--) {
    const northWest = project(north, west, candidate)
    const southEast = project(south, east, candidate)
    if (southEast.x - northWest.x <= size.width * 0.86 && southEast.y - northWest.y <= size.height * 0.8) { zoom = candidate; break }
  }
  const projectedNorthWest = project(north, west, zoom)
  const projectedSouthEast = project(south, east, zoom)
  const center = { x: (projectedNorthWest.x + projectedSouthEast.x) / 2, y: (projectedNorthWest.y + projectedSouthEast.y) / 2 }
  const viewport = { left: center.x - size.width / 2, top: center.y - size.height / 2 }
  const firstTileX = Math.floor(viewport.left / 256)
  const lastTileX = Math.floor((viewport.left + size.width) / 256)
  const firstTileY = Math.floor(viewport.top / 256)
  const lastTileY = Math.floor((viewport.top + size.height) / 256)
  const tileCount = 2 ** zoom
  const tiles = []
  for (let y = firstTileY; y <= lastTileY; y++) for (let x = firstTileX; x <= lastTileX; x++) {
    if (y >= 0 && y < tileCount) tiles.push({ x, y, sourceX: ((x % tileCount) + tileCount) % tileCount })
  }
  return <div className="courier-osm" ref={mapRef} role="img" aria-label={language === 'tk' ? 'Kurýerleriň kartasy' : 'Карта курьеров'}>
    <div className="osm-tiles">{tiles.map(tile => <img key={`${tile.x}-${tile.y}`} src={`https://tile.openstreetmap.org/${zoom}/${tile.sourceX}/${tile.y}.png`} alt="" draggable={false} style={{ left: tile.x * 256 - viewport.left, top: tile.y * 256 - viewport.top }} />)}</div>
    <div className="courier-markers">{located.map(courier => {
      const point = project(courier.latitude, courier.longitude, zoom)
      return <button key={courier.id} className={`courier-marker ${courier.is_available ? 'available' : ''}`} style={{ left: point.x - viewport.left, top: point.y - viewport.top }} title={`${courier.name} · ${transportName(language, courier.transport)}`} aria-label={courier.name}><span>{courier.name.split(' ').map(part => part[0]).join('').slice(0, 2)}</span><b>{courier.name}</b></button>
    })}</div>
    {!located.length && <div className="map-no-locations">{language === 'tk' ? 'Kurýerleriň ýerleşýän ýeri entek ýok' : 'Местоположения курьеров пока недоступны'}</div>}
    <a className="osm-attribution" href="https://www.openstreetmap.org/copyright" target="_blank" rel="noreferrer">© OpenStreetMap</a>
  </div>
}

function Brand() {
  return <div className="brand"><img className="brand-mark" src={logo} alt="" /><span>menzil</span></div>
}

function Sidebar({ open, active, language, onClose, onLogout, onNavigate }: { open: boolean; active: string; language: Language; onClose: () => void; onLogout: () => void; onNavigate: (page: string) => void }) {
  const nav = [
    [LayoutDashboard, 'Диспетчерская'], [Box, 'Заказы'], [UsersRound, 'Курьеры'],
  ] as const
  return <aside className={`sidebar ${open ? 'open' : ''}`}>
    <div className="side-head"><Brand /><button className="icon-button mobile-only" onClick={onClose}><X size={19} /></button></div>
    <div className="workspace"><div className="workspace-logo">A</div><div><strong>Aşgabat</strong><span>{tr(language, 'Операционный центр')}</span></div><ChevronDown size={16} /></div>
    <nav>{nav.map(([Icon, label]) => <button className={active === label ? 'active' : ''} onClick={() => { onNavigate(label); onClose() }} key={label}><Icon size={19} /><span>{tr(language, label)}</span></button>)}</nav>
    <div className="side-spacer" />
    <div className="operator"><div className="avatar">MA</div><div><strong>Menzil Admin</strong><span>{tr(language, 'Диспетчер')}</span></div><button className="logout-button" onClick={onLogout} title={tr(language, 'Выйти')}><LogOut size={17} /></button></div>
  </aside>
}

function LoginPage({ language, onLogin }: { language: Language; onLogin: (token: string) => void }) {
  const [phone, setPhone] = useState('+99360000099')
  const [password, setPassword] = useState('password')
  const [error, setError] = useState('')
  const [submitting, setSubmitting] = useState(false)

  const submit = async (event: FormEvent) => {
    event.preventDefault()
    setSubmitting(true)
    setError('')
    try {
      const session = await login(phone, password)
      if (session.role !== 'admin') throw new Error(language === 'tk' ? 'Administrator hasaby gerek' : 'Требуется учётная запись администратора')
      saveSession(session)
      onLogin(session.access_token)
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : (language === 'tk' ? 'API bilen birigip bolmady' : 'Не удалось подключиться к API'))
    } finally {
      setSubmitting(false)
    }
  }

  return <main className="login-page"><form className="login-card" onSubmit={submit}>
    <Brand />
    <div><h1>{tr(language, 'Вход в диспетчерскую')}</h1><p>{tr(language, 'Подключение к Menzil API')}</p></div>
    <label>{tr(language, 'Телефон')}<input value={phone} onChange={event => setPhone(event.target.value)} autoComplete="username" required /></label>
    <label>{tr(language, 'Пароль')}<input type="password" value={password} onChange={event => setPassword(event.target.value)} autoComplete="current-password" required /></label>
    {error && <div className="login-error">{error}</div>}
    <button className="primary" disabled={submitting}>{tr(language, submitting ? 'Подключение…' : 'Войти')}</button>
    <small>Development: +99360000099 / password</small>
  </form></main>
}

function Metric({ icon: Icon, value, label, delta, tone }: { icon: typeof Box; value: number | string; label: string; delta: string; tone: string }) {
  return <article className="metric"><div className={`metric-icon ${tone}`}><Icon size={21} /></div><div className="metric-copy"><span>{label}</span><strong>{value}</strong></div><small>{delta}</small></article>
}

function DashboardDiagrams({ orders, couriers, language }: { orders: Order[]; couriers: AdminCourier[]; language: Language }) {
  const statusData = [
    [language === 'tk' ? 'Täze' : 'Новые', orders.filter(order => order.status === 'Новый').length, '#6b5ce7'],
    [language === 'tk' ? 'Bellenen' : 'Назначены', orders.filter(order => order.status === 'Курьер назначен').length, '#7092b3'],
    [language === 'tk' ? 'Ýolda' : 'В пути', orders.filter(order => order.status === 'В пути').length, '#35a47c'],
    [language === 'tk' ? 'Eltildi' : 'Готовы', orders.filter(order => order.status === 'Доставлен').length, '#d4a84f'],
    [language === 'tk' ? 'Ýatyryldy' : 'Отменены', orders.filter(order => order.status === 'Отменён').length, '#df735d'],
  ] as const
  const total = Math.max(orders.length, 1)
  let cursor = 0
  const stops = statusData.map(([, value, color]) => { const start = cursor; cursor += value / total * 100; return `${color} ${start}% ${cursor}%` }).join(', ')
  const topCouriers = [...couriers].sort((a, b) => b.active_orders - a.active_orders || a.name.localeCompare(b.name)).slice(0, 5)
  const maxLoad = Math.max(...topCouriers.map(courier => courier.active_orders), 1)
  const created = statusData[0][1]
  const assigned = statusData[1][1] + statusData[2][1] + statusData[3][1]
  const delivered = statusData[3][1]
  return <section className="diagram-grid">
    <article className="panel diagram-card"><div className="diagram-heading"><div><span>{language === 'tk' ? 'SARGYTLARYŇ GURLUŞY' : 'СТРУКТУРА ЗАКАЗОВ'}</span><h2>{language === 'tk' ? 'Hakyky wagt ýagdaýlary' : 'Статусы в реальном времени'}</h2></div><b>{orders.length}</b></div><div className="donut-layout"><div className="donut" style={{ background: orders.length ? `conic-gradient(${stops})` : '#ece9e3' }}><i><b>{orders.length}</b><span>{language === 'tk' ? 'sargyt' : 'заказов'}</span></i></div><div className="diagram-legend">{statusData.map(([label, value, color]) => <div key={label}><i style={{ background: color }}></i><span>{label}</span><b>{value}</b></div>)}</div></div></article>
    <article className="panel diagram-card"><div className="diagram-heading"><div><span>{language === 'tk' ? 'TOPARYŇ ÝÜKI' : 'НАГРУЗКА КОМАНДЫ'}</span><h2>{language === 'tk' ? 'Kurýerleriň işjeň sargytlary' : 'Активные заказы курьеров'}</h2></div><b>{couriers.reduce((sum, courier) => sum + courier.active_orders, 0)}</b></div><div className="load-chart">{topCouriers.map(courier => <div key={courier.id}><div className="load-track"><i style={{ height: `${Math.max(8, courier.active_orders / maxLoad * 100)}%` }}></i></div><span title={courier.name}>{courier.name.split(' ')[0]}</span></div>)}</div></article>
    <article className="panel diagram-card"><div className="diagram-heading"><div><span>{language === 'tk' ? 'ELTIP BERME TAPGYRLARY' : 'ВОРОНКА ДОСТАВКИ'}</span><h2>{language === 'tk' ? 'Sargydyň ýoly' : 'Путь заказа'}</h2></div><b>{delivered}</b></div><div className="funnel"><div><span>{language === 'tk' ? 'Döredildi' : 'Созданы'}</span><i style={{ width: '100%' }}></i><b>{orders.length}</b></div><div><span>{language === 'tk' ? 'Bellenildi' : 'Назначены'}</span><i style={{ width: `${Math.max(8, assigned / total * 100)}%` }}></i><b>{assigned}</b></div><div><span>{language === 'tk' ? 'Ýolda' : 'В пути'}</span><i style={{ width: `${Math.max(8, statusData[2][1] / total * 100)}%` }}></i><b>{statusData[2][1]}</b></div><div><span>{language === 'tk' ? 'Eltildi' : 'Доставлены'}</span><i style={{ width: `${Math.max(8, delivered / total * 100)}%` }}></i><b>{delivered}</b></div></div>{created > 0 && <p className="diagram-note"><AlertTriangle size={13} />{created} {language === 'tk' ? 'sargyt kurýere garaşýar' : 'заказов ожидают назначения'}</p>}</article>
  </section>
}

function CouriersPage({ items, query, language, onToggle }: { items: AdminCourier[]; query: string; language: Language; onToggle: (courier: AdminCourier) => void }) {
  const visible = useMemo(() => {
    const normalized = query.trim().toLowerCase()
    return items.filter(courier => !normalized || `${courier.name} ${courier.transport} ${transportName(language, courier.transport)}`.toLowerCase().includes(normalized))
  }, [items, query, language])
  const available = items.filter(courier => courier.is_available).length
  const activeOrders = items.reduce((total, courier) => total + courier.active_orders, 0)
  return <>
    <section className="courier-metrics">
      <Metric icon={UsersRound} value={items.length} label={tr(language, 'Всего курьеров')} delta={language === 'tk' ? 'Topar' : 'Команда'} tone="indigo" />
      <Metric icon={Truck} value={available} label={tr(language, 'Сейчас на линии')} delta={`${items.length ? Math.round(available / items.length * 100) : 0}%`} tone="green" />
      <Metric icon={PackageCheck} value={activeOrders} label={tr(language, 'Активных доставок')} delta={language === 'tk' ? 'Häzirki ýük' : 'Текущая нагрузка'} tone="sand" />
    </section>
    <section className="couriers-workspace">
      <div className="panel courier-directory"><div className="panel-head"><div><h2>{tr(language, 'Команда курьеров')}</h2><span>{visible.length} {language === 'tk' ? 'tapyldy · API maglumatlary' : 'найдено · данные API'}</span></div></div>
        <div className="courier-cards">{visible.map((courier, index) => <article className="courier-card" key={courier.id}>
          <div className={`avatar ${['mint','blue','orange','violet'][index % 4]}`}>{courier.name.split(' ').map(part => part[0]).join('').slice(0,2)}<i></i></div>
          <div className="courier-card-main"><h3>{courier.name}</h3><p><TransportLabel language={language} value={courier.transport} /> · {language === 'tk' ? 'reýting' : 'рейтинг'} {courier.rating.toFixed(1)}</p><div><span><b>{courier.active_orders}</b> {language === 'tk' ? 'işjeň sargyt' : 'активных заказов'}</span><span className={courier.is_available ? 'available' : 'offline'}>{tr(language, courier.is_available ? 'На линии' : 'Не доступен')}</span></div></div>
          <button className={courier.is_available ? 'availability active' : 'availability'} onClick={() => onToggle(courier)} aria-label={`${tr(language, 'Изменить доступность')}: ${courier.name}`}><i></i></button>
        </article>)}</div>
        {!visible.length && <div className="empty"><Search size={24} /><b>{language === 'tk' ? 'Kurýer tapylmady' : 'Курьеры не найдены'}</b><span>{language === 'tk' ? 'Gözleg sözüni üýtgediň' : 'Измените поисковый запрос'}</span></div>}
      </div>
      <div className="panel courier-map-panel"><div className="panel-head"><div><h2>{tr(language, 'Карта команды')}</h2><span>{items.filter(courier => courier.latitude != null && courier.longitude != null).length}/{items.length} {language === 'tk' ? 'kurýer kartada' : 'курьеров на карте'}</span></div><button className="ghost" onClick={() => window.open('https://www.openstreetmap.org/#map=12/37.94/58.38', '_blank', 'noopener,noreferrer')}>{tr(language, 'Открыть')}</button></div><CouriersMap couriers={items} language={language} /><div className="map-summary"><span><i className="online-dot"></i>{available} {language === 'tk' ? 'işde' : 'на линии'}</span><span>{activeOrders} {language === 'tk' ? 'işjeň eltip berme' : 'активных доставок'}</span></div></div>
    </section>
  </>
}

function OrdersTable({ items, selected, onSelect, filter, query, language }: { items: Order[]; selected: number; onSelect: (id: number) => void; filter: string; query: string; language: Language }) {
  const visible = useMemo(() => items.filter(o => {
    const matchesFilter = filter === 'Все' || o.status === filter
    const q = query.toLowerCase()
    return matchesFilter && (!q || `${o.id} ${o.client} ${o.pickup} ${o.destination} ${o.courier}`.toLowerCase().includes(q))
  }), [items, filter, query])
  return <div className="orders-table">
    <div className="table-row table-head"><span>{tr(language, 'Заказ')}</span><span>{tr(language, 'Маршрут')}</span><span>{tr(language, 'Курьер')}</span><span>{tr(language, 'Статус')}</span><span>ETA</span><span></span></div>
    {visible.length ? visible.map(order => <button key={order.id} className={`table-row ${selected === order.id ? 'selected' : ''}`} onClick={() => onSelect(order.id)}>
      <span className="order-cell"><b>#{order.id}</b><small>{order.created} · {order.client}</small></span>
      <span className="route-cell"><i className="route-dots"><em></em><em></em></i><span><b>{order.pickup}</b><small>{order.destination}</small></span></span>
      <span className="courier-cell"><i>{order.courier === 'Не назначен' ? '?' : order.courier.split(' ').map(x => x[0]).join('')}</i><span><b>{tr(language, order.courier)}</b><small><TransportLabel language={language} value={order.vehicle} /></small></span></span>
      <span><i className={`status ${statusClass[order.status]}`}><i></i>{tr(language, order.status)}</i></span>
      <span className={order.status === 'Задержка' ? 'late-text' : ''}><b>{tr(language, order.eta)}</b><small>{order.price} TMT</small></span>
      <span><ChevronRight size={17} /></span>
    </button>) : <div className="empty"><Search size={24} /><b>{tr(language, 'Ничего не найдено')}</b><span>{tr(language, 'Попробуйте изменить фильтр или запрос')}</span></div>}
  </div>
}

function OrderDrawer({ order, couriers, language, onClose, onAction, onAssign, onStatus, onCall, onMessage }: { order: Order | undefined; couriers: AdminCourier[]; language: Language; onClose: () => void; onAction: (message: string) => void; onAssign: (courierId: string) => void; onStatus: (status: string) => void; onCall: () => void; onMessage: () => void }) {
  const [mapPoint, setMapPoint] = useState<'pickup' | 'delivery'>('pickup')
  if (!order) return null
  const latitude = mapPoint === 'pickup' ? order.pickupLatitude : order.deliveryLatitude
  const longitude = mapPoint === 'pickup' ? order.pickupLongitude : order.deliveryLongitude
  return <aside className="drawer">
    <div className="drawer-top"><div><span>{tr(language, 'Заказ')} #{order.id}</span><h2>{tr(language, order.status)}</h2></div><button className="icon-button" onClick={onClose}><X size={19} /></button></div>
    <div className="map-card">{latitude != null && longitude != null ? <OpenStreetMap latitude={latitude} longitude={longitude} label={mapPoint === 'pickup' ? order.pickup : order.destination} /> : <div className="map-empty">{tr(language, 'Координаты недоступны')}</div>}<div className="map-switch"><button className={mapPoint === 'pickup' ? 'active' : ''} onClick={() => setMapPoint('pickup')}><Box size={13} />{tr(language, 'Откуда')}</button><button className={mapPoint === 'delivery' ? 'active' : ''} onClick={() => setMapPoint('delivery')}><Map size={13} />{tr(language, 'Куда')}</button></div><button className="map-external" onClick={() => latitude != null && longitude != null && window.open(`https://www.openstreetmap.org/?mlat=${latitude}&mlon=${longitude}#map=15/${latitude}/${longitude}`, '_blank', 'noopener,noreferrer')} title={tr(language, 'Открыть')}><LocateFixed size={16} /></button></div>
    <div className="progress-copy"><span>{tr(language, 'Прогресс доставки')}</span><b>{order.progress}%</b></div><div className="progress"><i style={{ width: `${order.progress}%` }}></i></div>
    <div className="timeline">
      <div className="done"><i><Check size={13} /></i><div><b>{tr(language, 'Заказ принят')}</b><span>{order.created}</span></div></div>
      <div className={order.progress > 30 ? 'done' : ''}><i><Check size={13} /></i><div><b>{tr(language, 'Курьер забрал отправление')}</b><span>{order.progress > 30 ? '10:42' : tr(language, 'Ожидается')}</span></div></div>
      <div className={order.progress > 85 ? 'done' : 'current'}><i><Navigation size={12} /></i><div><b>{tr(language, 'Доставка получателю')}</b><span>{tr(language, order.eta)}</span></div></div>
    </div>
    <div className="detail-route"><div><i className="green"></i><span><small>{tr(language, 'Откуда')}</small><b>{order.pickup}</b></span></div><div><i className="purple"></i><span><small>{tr(language, 'Куда')}</small><b>{order.destination}</b></span></div></div>
    <div className="drawer-section-title">{tr(language, 'Курьер')}</div>
    <div className="driver"><div className="avatar dark">{order.courier === 'Не назначен' ? '?' : order.courier.split(' ').map(x => x[0]).join('')}</div><div><b>{tr(language, order.courier)}</b><TransportLabel language={language} value={order.vehicle} /></div><button onClick={onCall} title={tr(language, 'Позвонить')}><Phone size={17} /></button><button onClick={onMessage} title={tr(language, 'Написать')}><MessageSquareText size={17} /></button></div>
    <div className="note"><b>{tr(language, 'Комментарий')}</b><p>{order.note}</p></div>
    {order.apiId && <div className="admin-controls"><label>{tr(language, 'Назначить курьера')}<select defaultValue="" onChange={event => event.target.value && onAssign(event.target.value)}><option value="" disabled>{tr(language, 'Выберите курьера')}</option>{couriers.map(courier => <option value={courier.id} key={courier.id}>{courier.name} · {transportName(language, courier.transport)}</option>)}</select></label><div><button onClick={() => onStatus('to_pickup')}>{tr(language, 'К точке')}</button><button onClick={() => onStatus('delivering')}>{tr(language, 'В пути')}</button><button onClick={() => onStatus('delivered')}>{tr(language, 'Доставлен')}</button><button className="danger" onClick={() => onStatus('cancelled')}>{tr(language, 'Отменить')}</button></div></div>}
    <div className="drawer-actions"><button className="secondary" onClick={onMessage}><MessageSquareText size={17} />{tr(language, 'Написать')}</button><button className="primary" onClick={() => order.status === 'Новый' ? onAction(tr(language, 'Сначала назначьте курьера')) : onStatus(order.status === 'Курьер назначен' ? 'to_pickup' : order.status === 'В пути' ? 'delivered' : 'delivering')}>{tr(language, 'Следующий статус')}</button></div>
  </aside>
}

function NewOrderModal({ language, onClose, onCreate }: { language: Language; onClose: () => void; onCreate: (order: CreateAdminOrder) => Promise<void> }) {
  const [clientPhone, setClientPhone] = useState('+99360000001')
  const [deliveryPhone, setDeliveryPhone] = useState('+99360000004')
  const [title, setTitle] = useState(language === 'tk' ? 'Eltip berme' : 'Доставка')
  const [pickup, setPickup] = useState('')
  const [destination, setDestination] = useState('')
  const [price, setPrice] = useState('50')
  const [transport, setTransport] = useState('car')
  const [error, setError] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const submit = async (event: FormEvent) => {
    event.preventDefault()
    setSubmitting(true); setError('')
    try { await onCreate({ client_phone: clientPhone, delivery_phone: deliveryPhone, title, description: language === 'tk' ? 'Dispetçer tarapyndan döredildi' : 'Создано диспетчером', transport, pickup_address: pickup, delivery_address: destination, price: Number(price) }) }
    catch (reason) { setError(reason instanceof Error ? reason.message : (language === 'tk' ? 'Sargyt döredilmedi' : 'Заказ не создан')) }
    finally { setSubmitting(false) }
  }
  return <div className="modal-backdrop" onMouseDown={event => event.target === event.currentTarget && onClose()}><form className="modal-card" onSubmit={submit}>
    <div className="modal-head"><div><small>{tr(language, 'НОВЫЙ ЗАКАЗ')}</small><h2>{tr(language, 'Создать доставку')}</h2></div><button type="button" className="icon-button" onClick={onClose}><X size={18} /></button></div>
    <label>{tr(language, 'Телефон клиента')}<input value={clientPhone} onChange={event => setClientPhone(event.target.value)} required /></label>
    <label>{tr(language, 'Название')}<input value={title} onChange={event => setTitle(event.target.value)} required /></label>
    <label>{tr(language, 'Откуда')}<input value={pickup} onChange={event => setPickup(event.target.value)} placeholder={tr(language, 'Адрес отправления')} required /></label>
    <label>{tr(language, 'Куда')}<input value={destination} onChange={event => setDestination(event.target.value)} placeholder={tr(language, 'Адрес получателя')} required /></label>
    <label>{tr(language, 'Телефон получателя')}<input value={deliveryPhone} onChange={event => setDeliveryPhone(event.target.value)} required /></label>
    <label>{tr(language, 'Транспорт')}<select value={transport} onChange={event => setTransport(event.target.value)}><option value="foot">{tr(language, 'Пешком')}</option><option value="bicycle">{tr(language, 'Велосипед')}</option><option value="scooter">{tr(language, 'Скутер')}</option><option value="car">{tr(language, 'Автомобиль')}</option><option value="truck">{tr(language, 'Грузовик')}</option></select></label>
    <label>{tr(language, 'Стоимость, TMT')}<input type="number" min="1" value={price} onChange={event => setPrice(event.target.value)} required /></label>
    {error && <div className="login-error">{error}</div>}
    <div className="modal-actions"><button type="button" className="secondary" onClick={onClose}>{tr(language, 'Отмена')}</button><button className="primary" disabled={submitting}>{tr(language, submitting ? 'Создание…' : 'Создать заказ')}</button></div>
  </form></div>
}

export function App() {
  const [token, setToken] = useState(() => localStorage.getItem('menzil_token'))
  const [language, setLanguage] = useState<Language>(() => localStorage.getItem('menzil_language') === 'tk' ? 'tk' : 'ru')
  const [page, setPage] = useState('Диспетчерская')
  const [orderItems, setOrderItems] = useState<Order[]>([])
  const [courierItems, setCourierItems] = useState<AdminCourier[]>([])
  const [sideOpen, setSideOpen] = useState(false)
  const [drawerOpen, setDrawerOpen] = useState(false)
  const [selected, setSelected] = useState(0)
  const [filter, setFilter] = useState('Все')
  const [query, setQuery] = useState('')
  const [online, setOnline] = useState(true)
  const [overview, setOverview] = useState<AdminOverview>({ clients: 0, couriers: 0, open_orders: 0, available_couriers: 0, delivered_today: 0, complaints: 0 })
  const [toast, setToast] = useState('')
  const [newOrderOpen, setNewOrderOpen] = useState(false)
  const [notificationsOpen, setNotificationsOpen] = useState(false)
  const [extraFilters, setExtraFilters] = useState(false)
  const [apiError, setApiError] = useState('')

  async function loadAdminData(currentToken: string) {
    const [overviewResult, ordersResult, couriersResult] = await Promise.all([getAdminOverview(currentToken), getAdminOrders(currentToken), getAdminCouriers(currentToken)])
    setOverview(overviewResult)
    const mappedOrders = ordersResult.items.map(fromApiOrder)
    setOrderItems(mappedOrders)
    setSelected(previous => mappedOrders.some(order => order.id === previous) ? previous : (mappedOrders[0]?.id ?? 0))
    setCourierItems(couriersResult.items)
    setApiError('')
  }

  useEffect(() => {
    if (!token) return
    loadAdminData(token).catch(reason => setApiError(reason instanceof Error ? reason.message : 'API недоступен'))
    const refresh = () => loadAdminData(token).catch(reason => setApiError(reason instanceof Error ? reason.message : 'API недоступен'))
    const timer = window.setInterval(refresh, 5000)
    const onVisible = () => { if (document.visibilityState === 'visible') refresh() }
    document.addEventListener('visibilitychange', onVisible)
    return () => { window.clearInterval(timer); document.removeEventListener('visibilitychange', onVisible) }
  }, [token])

  useEffect(() => {
    const onRefreshed = (event: Event) => setToken((event as CustomEvent<string>).detail)
    const onExpired = () => setToken(null)
    window.addEventListener('menzil:token-refreshed', onRefreshed)
    window.addEventListener('menzil:session-expired', onExpired)
    return () => {
      window.removeEventListener('menzil:token-refreshed', onRefreshed)
      window.removeEventListener('menzil:session-expired', onExpired)
    }
  }, [])

  useEffect(() => {
    const focusSearch = (event: KeyboardEvent) => {
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k') {
        event.preventDefault()
        document.querySelector<HTMLInputElement>('.global-search input')?.focus()
      }
      if (event.key === 'Escape') { setNewOrderOpen(false); setNotificationsOpen(false); setDrawerOpen(false) }
    }
    window.addEventListener('keydown', focusSearch)
    return () => window.removeEventListener('keydown', focusSearch)
  }, [])

  if (!token) return <LoginPage language={language} onLogin={setToken} />

  const logout = () => { clearSession(); setToken(null) }
  const changeLanguage = (next: Language) => { localStorage.setItem('menzil_language', next); setLanguage(next) }

  const notify = (message: string) => { setToast(message); window.setTimeout(() => setToast(''), 2600) }
  const chooseOrder = (id: number) => { setSelected(id); setDrawerOpen(true) }
  const current = orderItems.find(o => o.id === selected)
  const workingOrders = orderItems.filter(order => ['Новый', 'Курьер назначен', 'В пути'].includes(order.status))
  const currentHour = new Date().getHours()
  const greeting = currentHour < 12 ? 'Доброе утро' : currentHour < 18 ? 'Добрый день' : 'Добрый вечер'
  const navigate = (nextPage: string) => {
    setPage(nextPage)
    setQuery('')
    setFilter('Все')
  }
  const createOrder = async (order: CreateAdminOrder) => {
    const created = await createAdminOrder(token, order)
    await loadAdminData(token)
    setSelected(created.public_number)
    setNewOrderOpen(false)
    setPage('Заказы')
    setDrawerOpen(true)
    notify(language === 'tk' ? `#${created.public_number} sargyt API-da döredildi` : `Заказ #${created.public_number} создан в API`)
  }
  const updateOrderStatus = async (status: string) => {
    if (!current?.apiId) return
    try { await setAdminOrderStatus(token, current.apiId, status); await loadAdminData(token); notify(language === 'tk' ? 'Sargydyň ýagdaýy täzelendi' : 'Статус заказа обновлён') }
    catch (reason) { notify(reason instanceof Error ? reason.message : (language === 'tk' ? 'Ýagdaý täzelenmedi' : 'Статус не обновлён')) }
  }
  const assignCourier = async (courierId: string) => {
    if (!current?.apiId) return
    try { await assignAdminCourier(token, current.apiId, courierId); await loadAdminData(token); notify(language === 'tk' ? 'Kurýer bellenildi' : 'Курьер назначен') }
    catch (reason) { notify(reason instanceof Error ? reason.message : (language === 'tk' ? 'Kurýer bellenilmedi' : 'Курьер не назначен')) }
  }
  const toggleCourier = async (courier: AdminCourier) => {
    try { await setAdminCourierAvailability(token, courier.id, !courier.is_available); await loadAdminData(token); notify(language === 'tk' ? 'Kurýeriň elýeterliligi täzelendi' : 'Доступность курьера обновлена') }
    catch (reason) { notify(reason instanceof Error ? reason.message : (language === 'tk' ? 'Kurýer täzelenmedi' : 'Курьер не обновлён')) }
  }
  const callCurrentOrder = async () => {
    if (!current?.apiId) return
    try { const call = await startOrderCall(token, current.apiId); notify(`${language === 'tk' ? 'Jaň döredildi' : 'Звонок создан'}: ${call.room_id.slice(0, 8)}`) }
    catch (reason) { notify(reason instanceof Error ? reason.message : (language === 'tk' ? 'Jaň döredilmedi' : 'Звонок не создан')) }
  }
  const messageCurrentOrder = async () => {
    if (!current?.apiId) return
    const body = window.prompt(language === 'tk' ? `#${current.id} sargyt boýunça habar` : `Сообщение по заказу #${current.id}`)?.trim()
    if (!body) return
    try { await sendOrderMessage(token, current.apiId, body); notify(language === 'tk' ? 'Habar ugradyldy' : 'Сообщение отправлено') }
    catch (reason) { notify(reason instanceof Error ? reason.message : (language === 'tk' ? 'Habar ugradylmady' : 'Сообщение не отправлено')) }
  }

  return <div className="app-shell">
    <Sidebar open={sideOpen} active={page} language={language} onClose={() => setSideOpen(false)} onLogout={logout} onNavigate={navigate} />
    {sideOpen && <button className="backdrop" onClick={() => setSideOpen(false)} aria-label={tr(language, 'Закрыть меню')} />}
    <main className="main">
      <header className="topbar">
        <button className="icon-button mobile-only" onClick={() => setSideOpen(true)}><Menu size={20} /></button>
        <div className="mobile-brand mobile-only"><Brand /></div>
        <label className="global-search"><Search size={18} /><input value={query} onChange={e => setQuery(e.target.value)} placeholder={language === 'tk' ? (page === 'Курьеры' ? 'Kurýeriň ady ýa-da ulagy' : 'Sargyt, salgy ýa-da kurýer') : (page === 'Курьеры' ? 'Имя или транспорт курьера' : 'Заказ, адрес или курьер')} /><kbd><Command size={12} /> K</kbd></label>
        <div className="top-actions"><div className="language-switch"><button className={language === 'ru' ? 'active' : ''} onClick={() => changeLanguage('ru')}>RU</button><button className={language === 'tk' ? 'active' : ''} onClick={() => changeLanguage('tk')}>TK</button></div><button className={`shift ${online ? 'online' : ''}`} onClick={() => { setOnline(!online); notify(language === 'tk' ? (online ? 'Iş wagty togtadyldy' : 'Siz ýene işde') : (online ? 'Смена приостановлена' : 'Вы снова на линии')) }}><i></i>{language === 'tk' ? (online ? 'Işjeň' : 'Arakesme') : (online ? 'Смена активна' : 'Смена на паузе')}<ChevronDown size={15} /></button><div className="notification-wrap"><button className="icon-button notification" onClick={() => setNotificationsOpen(open => !open)} aria-label={tr(language, 'Уведомления')}><Bell size={19} />{orderItems.some(order => order.status === 'Новый') && <i></i>}</button>{notificationsOpen && <div className="notification-menu"><b>{language === 'tk' ? 'Bildirişler' : 'Уведомления'}</b><button onClick={() => { setFilter('Новый'); setPage('Заказы'); setNotificationsOpen(false) }}>{orderItems.filter(order => order.status === 'Новый').length} {language === 'tk' ? 'sargyt kurýere garaşýar' : 'заказов ждут курьера'}<span>{language === 'tk' ? 'Sargytlary açmak' : 'Открыть заказы'}</span></button><button onClick={() => { setPage('Курьеры'); setNotificationsOpen(false) }}>{courierItems.filter(courier => courier.is_available).length} {language === 'tk' ? 'kurýer elýeterli' : 'курьеров доступны'}<span>{language === 'tk' ? 'Topary görmek' : 'Посмотреть команду'}</span></button></div>}</div></div>
      </header>
      <div className="content">
        {apiError && <div className="api-banner"><AlertTriangle size={16} /><span>{apiError}</span><button onClick={() => loadAdminData(token)}>{tr(language, 'Повторить')}</button><button onClick={logout}>{tr(language, 'Войти снова')}</button></div>}
        <section className={`page-title ${page === 'Диспетчерская' ? 'dashboard-hero' : ''}`}><div><p>{new Intl.DateTimeFormat(language === 'tk' ? 'tk-TM' : 'ru-RU', { weekday: 'long', day: 'numeric', month: 'long' }).format(new Date()).toUpperCase()}</p><h1>{page === 'Диспетчерская' ? (language === 'tk' ? 'Hoş geldiňiz, dispetçer' : `${greeting}, диспетчер`) : page === 'Заказы' ? tr(language, 'Все заказы') : tr(language, page)}</h1><span>{page === 'Диспетчерская' ? (language === 'tk' ? `${overview.open_orders} işjeň sargyt · ${overview.available_couriers} kurýer eltip bermäge taýýar` : `${overview.open_orders} активных заказов · ${overview.available_couriers} курьеров готовы принять доставку`) : page === 'Заказы' ? `${orderItems.length} ${language === 'tk' ? 'API sargydy' : 'заказов из API'}` : 'Menzil admin'}</span></div><button className="primary" onClick={() => setNewOrderOpen(true)}><Plus size={18} />{tr(language, 'Новый заказ')}</button></section>
        {page === 'Курьеры' ? <CouriersPage items={courierItems} query={query} language={language} onToggle={toggleCourier} /> : <>{page === 'Диспетчерская' && <><section className="metrics">
          <Metric icon={Zap} value={overview.open_orders} label={tr(language, 'Активные заказы')} delta={`${orderItems.filter(order => order.status === 'Новый').length} ${language === 'tk' ? 'kurýere garaşýar' : 'ждут курьера'}`} tone="indigo" />
          <Metric icon={Truck} value={overview.available_couriers} label={tr(language, 'Курьеры на линии')} delta={`${overview.couriers ? Math.round(overview.available_couriers / overview.couriers * 100) : 0}%`} tone="green" />
          <Metric icon={PackageCheck} value={overview.delivered_today} label={tr(language, 'Доставлено сегодня')} delta="API" tone="sand" />
          <Metric icon={AlertTriangle} value={overview.complaints} label={tr(language, 'Требуют внимания')} delta={`${orderItems.filter(order => order.status === 'Отменён').length} ${language === 'tk' ? 'ýatyryldy' : 'отменено'}`} tone="coral" />
        </section><DashboardDiagrams orders={orderItems} couriers={courierItems} language={language} /></>}
        <section className={`work-grid ${page === 'Заказы' ? 'orders-view' : ''}`}>
          <div className="orders-panel panel">
            <div className="panel-head"><div><h2>{tr(language, page === 'Заказы' ? 'Все заказы' : 'Заказы в работе')}</h2><span>{page === 'Заказы' ? orderItems.length : workingOrders.length} {language === 'tk' ? 'ýazgy · täzelendi' : 'записей · обновлено'}</span></div>{page !== 'Заказы' && <button className="ghost" onClick={() => { setPage('Заказы'); setFilter('Все'); setQuery('') }}>{tr(language, 'Все заказы')} <ArrowRight size={16} /></button>}</div>
            <div className="filter-row"><div className="filters">{(page === 'Заказы' ? ['Все', 'Новый', 'Курьер назначен', 'В пути', 'Доставлен', 'Отменён'] : ['Все', 'Новый', 'Курьер назначен', 'В пути']).map(item => <button className={filter === item ? 'active' : ''} onClick={() => setFilter(item)} key={item}>{tr(language, item)}{item === 'Отменён' && <i>{orderItems.filter(order => order.status === 'Отменён').length}</i>}</button>)}</div><button className={`filter-button ${extraFilters ? 'active' : ''}`} onClick={() => setExtraFilters(value => !value)}><SlidersHorizontal size={16} />{tr(language, 'Фильтры')}</button></div>
            {extraFilters && <div className="advanced-filters"><span>{tr(language, 'Быстрые фильтры')}</span><button onClick={() => setQuery('Не назначен')}>{tr(language, 'Без курьера')}</button><button onClick={() => setQuery('Центр')}>{tr(language, 'Центр')}</button><button onClick={() => { setQuery(''); setFilter('Все') }}>{tr(language, 'Сбросить')}</button></div>}
            <OrdersTable items={page === 'Заказы' ? orderItems : workingOrders} selected={selected} onSelect={chooseOrder} filter={filter} query={query} language={language} />
          </div>
          {page === 'Диспетчерская' && <aside className="right-column">
            <div className="panel courier-panel"><div className="panel-head"><div><h2>{tr(language, 'Курьеры')}</h2><span>{tr(language, 'Данные API в реальном времени')}</span></div><button className="ghost" onClick={() => window.open('https://www.openstreetmap.org/#map=12/37.94/58.38', '_blank', 'noopener,noreferrer')}>{tr(language, 'На карте')}</button></div>
              <div className="courier-list">{courierItems.map((courier, index) => <div className="courier" key={courier.id}><div className={`avatar ${['mint','blue','orange','violet'][index % 4]}`}>{courier.name.split(' ').map(part => part[0]).join('').slice(0,2)}<i></i></div><div><b>{courier.name}</b><span><TransportLabel language={language} value={courier.transport} /> · {courier.active_orders} {language === 'tk' ? 'sargyt' : 'заказа'}</span></div><small className={courier.is_available ? '' : 'warn'}>{tr(language, courier.is_available ? 'На линии' : 'Не доступен')}</small><button onClick={() => toggleCourier(courier)} title={tr(language, 'Изменить доступность')}><MoreHorizontal size={17} /></button></div>)}</div>
              <button className="wide-ghost" onClick={() => setPage('Курьеры')}>{tr(language, 'Все курьеры')} <ChevronRight size={16} /></button>
            </div>
          </aside>}
        </section></>}
      </div>
    </main>
    {drawerOpen && <><button className="drawer-backdrop" onClick={() => setDrawerOpen(false)} /><OrderDrawer order={current} couriers={courierItems} language={language} onClose={() => setDrawerOpen(false)} onAction={notify} onAssign={assignCourier} onStatus={updateOrderStatus} onCall={callCurrentOrder} onMessage={messageCurrentOrder} /></>}
    {newOrderOpen && <NewOrderModal language={language} onClose={() => setNewOrderOpen(false)} onCreate={createOrder} />}
    {toast && <div className="toast"><Check size={17} />{toast}</div>}
  </div>
}
