package routes

import (
	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"

	"menzil/internal/auth"
	"menzil/internal/config"
	"menzil/internal/middleware"
	"menzil/internal/orders"
	"menzil/internal/tracking"
)

func Register(router *gin.Engine, db *pgxpool.Pool, cfg config.Config) {
	tokens := auth.NewTokenManager(cfg.JWTSecret, cfg.AccessTokenTTL)
	authHandler := auth.NewHandler(db, tokens)
	orderHandler := orders.NewHandler(orders.NewService(db))
	trackingHandler := tracking.NewHandler(db, tracking.NewHub())

	router.GET("/healthz", func(c *gin.Context) { c.JSON(200, gin.H{"status": "ok"}) })
	v1 := router.Group("/v1")
	v1.POST("/auth/register", authHandler.Register)
	v1.POST("/auth/login", authHandler.Login)

	protected := v1.Group("")
	protected.Use(middleware.Authenticate(tokens))
	client := protected.Group("")
	client.Use(middleware.RequireRole("client"))
	client.POST("/orders", orderHandler.Create)

	courier := protected.Group("/courier")
	courier.Use(middleware.RequireRole("courier"))
	courier.PUT("/availability", orderHandler.SetAvailability)
	courier.GET("/orders/available", orderHandler.Available)
	courier.GET("/orders/active", orderHandler.Active)
	courier.POST("/orders/:id/accept", orderHandler.Accept)
	courier.POST("/orders/:id/status", orderHandler.ChangeStatus)
	courier.GET("/ws/location", trackingHandler.CourierSocket)

	protected.GET("/orders/:id/tracking/ws", trackingHandler.ClientSocket)
}
