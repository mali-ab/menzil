.PHONY: api-db api-seed api-run api-fmt api-test mobile-init mobile-linux-init mobile-web-init mobile-run mobile-run-android mobile-run-web

api-db:
	cd api && docker compose up -d

api-seed:
	cd api && docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U menzil -d menzil < seeds/development.sql

api-run:
	cd api && go run ./cmd/api

api-fmt:
	cd api && gofmt -w $$(find . -name '*.go' -not -path './vendor/*')

api-test:
	cd api && go test ./...

mobile-init:
	cd mobile && flutter create --platforms=android,ios . && flutter pub get

mobile-linux-init:
	cd mobile && flutter create --platforms=linux . && flutter pub get

mobile-web-init:
	cd mobile && flutter create --platforms=web . && flutter pub get

mobile-run:
	cd mobile && flutter run -d linux --dart-define=API_BASE_URL=http://localhost:8080

mobile-run-android:
	cd mobile && flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080

mobile-run-web:
	cd mobile && flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
