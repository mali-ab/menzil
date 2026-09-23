package config

import (
	"log"
	"os"
	"time"
)

type Config struct {
	Address        string
	DatabaseURL    string
	JWTSecret      []byte
	AccessTokenTTL time.Duration
}

func Load() Config {
	ttl, err := time.ParseDuration(value("ACCESS_TOKEN_TTL", "15m"))
	if err != nil {
		log.Fatalf("ACCESS_TOKEN_TTL nädogry: %v", err)
	}
	secret := value("JWT_SECRET", "development-only-secret-change-me-please")
	if len(secret) < 32 {
		log.Fatal("JWT_SECRET azyndan 32 nyşan bolmaly")
	}
	return Config{
		Address:        value("APP_ADDRESS", ":8080"),
		DatabaseURL:    value("DATABASE_URL", "postgres://menzil:menzil@localhost:5432/menzil?sslmode=disable"),
		JWTSecret:      []byte(secret),
		AccessTokenTTL: ttl,
	}
}

func value(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}
