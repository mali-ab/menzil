package routes

import (
	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"

	"menzil/internal/admin"
	"menzil/internal/auth"
	"menzil/internal/communication"
	"menzil/internal/config"
	"menzil/internal/middleware"
	"menzil/internal/orders"
	"menzil/internal/profile"
	"menzil/internal/tracking"
)

func Register(router *gin.Engine, db *pgxpool.Pool, cfg config.Config) {
	tokens := auth.NewTokenManager(cfg.JWTSecret, cfg.AccessTokenTTL)
	authHandler := auth.NewHandler(db, tokens, cfg.RefreshTokenTTL)
	adminHandler := admin.NewHandler(db)
	orderHandler := orders.NewHandler(orders.NewService(db))
	communicationHandler := communication.NewHandler(db)
	trackingHandler := tracking.NewHandler(db, tracking.NewHub())
	profileHandler := profile.NewHandler(db)

	router.GET("/healthz", func(c *gin.Context) { c.JSON(200, gin.H{"status": "ok", "admin_api": true}) })
	router.Static("/uploads", "./uploads")
	v1 := router.Group("/v1")
	v1.POST("/auth/register", authHandler.Register)
	v1.POST("/auth/login", authHandler.Login)
	v1.POST("/auth/refresh", authHandler.Refresh)

	protected := v1.Group("")
	protected.Use(middleware.Authenticate(tokens))
	protected.GET("/profile", profileHandler.Get)
	protected.PUT("/profile", profileHandler.Update)
	client := protected.Group("")
	client.Use(middleware.RequireRole("client"))
	client.POST("/orders", orderHandler.Create)
	client.POST("/orders/:id/proof/otp/refresh", orderHandler.RefreshOTP)
	protected.GET("/orders/my", orderHandler.Mine)
	protected.GET("/orders/:id/messages", communicationHandler.Messages)
	protected.POST("/orders/:id/messages", communicationHandler.Send)
	protected.POST("/orders/:id/call", communicationHandler.StartCall)

	courier := protected.Group("/courier")
	courier.Use(middleware.RequireRole("courier"))
	courier.PUT("/availability", orderHandler.SetAvailability)
	courier.GET("/orders/available", orderHandler.Available)
	courier.GET("/orders/active", orderHandler.Active)
	courier.POST("/orders/:id/accept", orderHandler.Accept)
	courier.POST("/orders/:id/status", orderHandler.ChangeStatus)
	courier.POST("/orders/:id/proof/otp", orderHandler.VerifyOTP)
	courier.POST("/orders/:id/proof/photo", orderHandler.SubmitPhoto)
	courier.GET("/ws/location", trackingHandler.CourierSocket)

	protected.GET("/orders/:id/tracking/ws", trackingHandler.ClientSocket)
	adminGroup := protected.Group("/admin")
	adminGroup.Use(middleware.RequireRole("admin"))
	adminGroup.GET("/overview", adminHandler.Overview)
	adminGroup.GET("/orders", adminHandler.Orders)
	adminGroup.POST("/orders", adminHandler.CreateOrder)
	adminGroup.PUT("/orders/:id/status", adminHandler.SetOrderStatus)
	adminGroup.PUT("/orders/:id/courier", adminHandler.AssignCourier)
	adminGroup.GET("/couriers", adminHandler.Couriers)
	adminGroup.PUT("/couriers/:id/availability", adminHandler.SetCourierAvailability)
}
