const apiBase = (import.meta.env.VITE_API_BASE_URL || (import.meta.env.PROD ? '' : 'http://localhost:8080')).replace(/\/$/, '')

type LoginResponse = {
  access_token: string
  refresh_token: string
  token_type: string
  user_id: string
  role: string
}

export type AdminOverview = {
  clients: number
  couriers: number
  available_couriers: number
  open_orders: number
  delivered_today: number
  complaints: number
}

export type AdminOrder = {
  id: string
  public_number: number
  title: string
  description: string
  status: string
  pickup_address: string
  delivery_address: string
  price: number
  currency: string
  transport: string
  created_at: string
  client: string
  courier: string
  courier_id: string
  pickup_latitude: number
  pickup_longitude: number
  delivery_latitude: number
  delivery_longitude: number
}

export type AdminCourier = {
  id: string
  name: string
  transport: string
  is_available: boolean
  rating: number
  active_orders: number
  latitude: number | null
  longitude: number | null
  location_recorded_at: string | null
}

export type CreateAdminOrder = {
  client_phone: string
  title: string
  description: string
  transport: string
  pickup_address: string
  delivery_address: string
  delivery_phone: string
  price: number
}

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(`${apiBase}${path}`, { cache: 'no-store', ...init })
  const body = await response.json().catch(() => ({})) as { error?: string }
  if (!response.ok) throw new ApiError(body.error || `API request failed (${response.status})`, response.status)
  return body as T
}

class ApiError extends Error {
  constructor(message: string, readonly status: number) {
    super(message)
  }
}

let refreshInFlight: Promise<string> | null = null

export function saveSession(session: LoginResponse) {
  localStorage.setItem('menzil_token', session.access_token)
  localStorage.setItem('menzil_refresh_token', session.refresh_token)
}

export function clearSession() {
  localStorage.removeItem('menzil_token')
  localStorage.removeItem('menzil_refresh_token')
}

function refreshAccessToken() {
  if (refreshInFlight) return refreshInFlight
  const refreshToken = localStorage.getItem('menzil_refresh_token')
  if (!refreshToken) {
    clearSession()
    window.dispatchEvent(new Event('menzil:session-expired'))
    return Promise.reject(new Error('Сессия истекла. Войдите снова.'))
  }

  refreshInFlight = request<LoginResponse>('/v1/auth/refresh', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ refresh_token: refreshToken }),
  }).then(session => {
    if (session.role !== 'admin') throw new Error('Требуется учётная запись администратора')
    saveSession(session)
    window.dispatchEvent(new CustomEvent('menzil:token-refreshed', { detail: session.access_token }))
    return session.access_token
  }).catch(reason => {
    clearSession()
    window.dispatchEvent(new Event('menzil:session-expired'))
    throw reason
  }).finally(() => { refreshInFlight = null })
  return refreshInFlight
}

export function login(phone: string, password: string) {
  return request<LoginResponse>('/v1/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phone, password }),
  })
}

export function getAdminOverview(token: string) {
  return authorized<AdminOverview>(token, '/v1/admin/overview')
}

async function authorized<T>(token: string, path: string, init?: RequestInit) {
  const send = (accessToken: string) => request<T>(path, { ...init, headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${accessToken}`, ...init?.headers } })
  try {
    return await send(localStorage.getItem('menzil_token') || token)
  } catch (reason) {
    if (!(reason instanceof ApiError) || reason.status !== 401) throw reason
    return send(await refreshAccessToken())
  }
}

export function getAdminOrders(token: string) {
  return authorized<{ items: AdminOrder[] }>(token, '/v1/admin/orders')
}

export function createAdminOrder(token: string, payload: CreateAdminOrder) {
  return authorized<{ id: string; public_number: number; status: string }>(token, '/v1/admin/orders', { method: 'POST', body: JSON.stringify(payload) })
}

export function setAdminOrderStatus(token: string, id: string, status: string) {
  return authorized(token, `/v1/admin/orders/${id}/status`, { method: 'PUT', body: JSON.stringify({ status }) })
}

export function assignAdminCourier(token: string, orderId: string, courierId: string) {
  return authorized(token, `/v1/admin/orders/${orderId}/courier`, { method: 'PUT', body: JSON.stringify({ courier_id: courierId }) })
}

export function getAdminCouriers(token: string) {
  return authorized<{ items: AdminCourier[] }>(token, '/v1/admin/couriers')
}

export function setAdminCourierAvailability(token: string, id: string, isAvailable: boolean) {
  return authorized(token, `/v1/admin/couriers/${id}/availability`, { method: 'PUT', body: JSON.stringify({ is_available: isAvailable }) })
}

export function sendOrderMessage(token: string, orderId: string, body: string) {
  return authorized(token, `/v1/orders/${orderId}/messages`, { method: 'POST', body: JSON.stringify({ body }) })
}

export function startOrderCall(token: string, orderId: string) {
  return authorized<{ provider: string; room_id: string; expires_in_seconds: number }>(token, `/v1/orders/${orderId}/call`, { method: 'POST' })
}
