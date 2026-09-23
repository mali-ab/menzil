package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"

	"menzil/internal/config"
	"menzil/internal/middleware"
	"menzil/internal/platform/database"
	"menzil/internal/routes"
)

func main() {
	cfg := config.Load()
	ctx := context.Background()
	db, err := database.Connect(ctx, cfg.DatabaseURL)
	if err != nil { log.Fatalf("PostgreSQL birikmedi: %v", err) }
	defer db.Close()

	router := gin.New()
	router.Use(gin.Logger(), gin.Recovery(), middleware.CORS())
	routes.Register(router, db, cfg)

	server := &http.Server{Addr: cfg.Address, Handler: router, ReadHeaderTimeout: 5 * time.Second}
	go func() {
		log.Printf("API %s salgysynda başlady", cfg.Address)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed { log.Fatal(err) }
	}()
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)
	<-stop
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	_ = server.Shutdown(shutdownCtx)
}
