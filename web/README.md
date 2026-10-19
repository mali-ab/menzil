# Menzil Dispatch

Веб-интерфейс диспетчерской Menzil на React + TypeScript + Vite.

```sh
cd web
npm install
npm run dev
```

API по умолчанию ожидается на `http://localhost:8080`. Другой адрес можно задать в `.env`:

```sh
VITE_API_BASE_URL=https://api.example.com
```

Если в `localStorage` есть `menzil_token`, главные показатели загружаются из `GET /v1/admin/overview`. Без API интерфейс работает с демонстрационными данными.
