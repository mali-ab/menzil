.PHONY: api-db api-db-sync-default-password api-migrate api-seed api-deps api-run api-fmt api-test web-run dev-run production-run production-down production-logs mobile-init mobile-linux-init mobile-web-init mobile-run mobile-run-android mobile-run-web mobile-build-apk

api-db:
	@if command -v pg_isready >/dev/null 2>&1 && pg_isready -q; then \
		echo "PostgreSQL is already running locally."; \
	elif command -v systemctl >/dev/null 2>&1; then \
		sudo systemctl start postgresql; \
	elif command -v service >/dev/null 2>&1; then \
		sudo service postgresql start; \
	elif command -v brew >/dev/null 2>&1; then \
		brew services start postgresql@16; \
	else \
		echo "Could not start local PostgreSQL: install PostgreSQL/PostGIS and start its service." >&2; \
		exit 1; \
	fi

api-db-sync-default-password: api-db
	@command -v psql >/dev/null 2>&1 || { echo "psql is required. Install PostgreSQL client tools." >&2; exit 1; }
	@if command -v sudo >/dev/null 2>&1 && id postgres >/dev/null 2>&1; then \
		sudo -u postgres psql -v ON_ERROR_STOP=1 -d postgres -c "ALTER ROLE menzil WITH LOGIN PASSWORD 'menzil';"; \
	else \
		psql -v ON_ERROR_STOP=1 -d postgres -c "ALTER ROLE menzil WITH LOGIN PASSWORD 'menzil';"; \
	fi

api-migrate: api-db
	@command -v psql >/dev/null 2>&1 || { echo "psql is required. Install PostgreSQL client tools." >&2; exit 1; }
	@cd api && \
		set -eu; \
		if [ -f .env ]; then set -a; . ./.env; set +a; fi; \
		db_url="$${DATABASE_URL:-postgres://menzil:menzil@localhost:5432/menzil?sslmode=disable}"; \
		if [ "$$(psql "$$db_url" -v ON_ERROR_STOP=1 -Atq -c "SELECT 1 FROM pg_available_extensions WHERE name = 'postgis';")" != "1" ]; then \
			pg_major=$$(psql "$$db_url" -v ON_ERROR_STOP=1 -Atq -c "SHOW server_version;" | cut -d. -f1); \
			echo "PostGIS is not installed for PostgreSQL $$pg_major." >&2; \
			echo "Debian/Ubuntu: sudo apt install postgresql-$$pg_major-postgis-3" >&2; \
			echo "Then run: make api-seed" >&2; \
			exit 1; \
		fi; \
		psql "$$db_url" -v ON_ERROR_STOP=1 -q -c "CREATE TABLE IF NOT EXISTS schema_migrations (version TEXT PRIMARY KEY, applied_at TIMESTAMPTZ NOT NULL DEFAULT now());"; \
		for migration in migrations/*.up.sql; do \
			version=$$(basename "$$migration" .up.sql); \
			if [ "$$(psql "$$db_url" -v ON_ERROR_STOP=1 -Atq -c "SELECT 1 FROM schema_migrations WHERE version = '$$version';")" != "1" ]; then \
				echo "Applying migration $$version"; \
				psql "$$db_url" -v ON_ERROR_STOP=1 -1 -f "$$migration" -c "INSERT INTO schema_migrations (version) VALUES ('$$version');"; \
			fi; \
		done

api-seed: api-migrate
	@command -v psql >/dev/null 2>&1 || { echo "psql is required. Install PostgreSQL client tools." >&2; exit 1; }
	cd api && if [ -f .env ]; then set -a; . ./.env; set +a; fi; psql "$${DATABASE_URL:-postgres://menzil:menzil@localhost:5432/menzil?sslmode=disable}" -v ON_ERROR_STOP=1 -f seeds/development.sql

api-deps:
	cd api && go mod tidy

api-run: api-deps
	cd api && if [ -f .env ]; then set -a; . ./.env; set +a; fi; go run ./cmd/api

api-fmt:
	cd api && gofmt -w $$(find . -name '*.go' -not -path './vendor/*')

api-test: api-deps
	cd api && go test ./...

web-run:
	cd web && npm run dev

dev-run:
	@set -e; \
		trap 'kill "$$api_pid" 2>/dev/null || true' EXIT INT TERM; \
		$(MAKE) api-run & api_pid=$$!; \
		ready=0; \
		for attempt in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do \
			if curl -fsS http://localhost:8080/healthz 2>/dev/null | grep -q '"admin_api":true'; then ready=1; break; fi; \
			sleep 0.5; \
		done; \
		if [ "$$ready" != 1 ]; then \
			echo "Current API did not start on port 8080. Stop any old API process and retry." >&2; \
			exit 1; \
		fi; \
		$(MAKE) web-run

production-run:
	@test -f production.env || { echo "Create production.env first: cp production.env.example production.env" >&2; exit 1; }
	docker compose --env-file production.env -f docker-compose.production.yml up --build -d

production-down:
	docker compose --env-file production.env -f docker-compose.production.yml down

production-logs:
	docker compose --env-file production.env -f docker-compose.production.yml logs -f api web

mobile-init:
	cd mobile && flutter create --platforms=android,ios . && flutter pub get

mobile-linux-init:
	cd mobile && flutter create --platforms=linux . && flutter pub get

mobile-web-init:
	cd mobile && flutter create --platforms=web . && flutter pub get

mobile-run:
	cd mobile && flutter run -d linux --dart-define=API_BASE_URL=http://localhost:8080

MOBILE_API_BASE_URL ?= http://192.168.137.102:8080

mobile-run-android:
	cd mobile && flutter run --dart-define=API_BASE_URL=$(MOBILE_API_BASE_URL)

mobile-build-apk:
	cd mobile && flutter pub get && \
		flutter build apk --debug --dart-define=API_BASE_URL=$(MOBILE_API_BASE_URL) && \
		flutter build apk --release --dart-define=API_BASE_URL=$(MOBILE_API_BASE_URL)

mobile-run-web:
	cd mobile && flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
