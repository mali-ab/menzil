package orders

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"menzil/internal/middleware"
)

type Handler struct{ service *Service }

func NewHandler(service *Service) *Handler { return &Handler{service: service} }

func (h *Handler) Create(c *gin.Context) {
	var req CreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	id, err := h.service.Create(c.Request.Context(), middleware.Current(c).UserID, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Sargyt döredilmedi"})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"id": id, "status": "created"})
}

func (h *Handler) Available(c *gin.Context) {
	orders, err := h.service.Available(c.Request.Context(), middleware.Current(c).UserID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Sargytlaryň sanawy alynmady"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"items": orders})
}

type availabilityRequest struct {
	IsAvailable bool `json:"is_available"`
}

func (h *Handler) SetAvailability(c *gin.Context) {
	var req availabilityRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	err := h.service.SetAvailability(c.Request.Context(), middleware.Current(c).UserID, req.IsAvailable)
	if errors.Is(err, ErrUnavailable) || errors.Is(err, ErrCapacity) {
		c.JSON(http.StatusNotFound, gin.H{"error": "Kurýer profili tapylmady"})
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Elýeterlilik üýtgedilmedi"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"is_available": req.IsAvailable})
}

func (h *Handler) Accept(c *gin.Context) {
	orderID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Sargyt ID-si nädogry"})
		return
	}
	err = h.service.Accept(c.Request.Context(), orderID, middleware.Current(c).UserID)
	if errors.Is(err, ErrUnavailable) {
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Sargyt kabul edilmedi"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"id": orderID, "status": "accepted"})
}

type statusRequest struct {
	Status string `json:"status" binding:"required,oneof=to_pickup delivering delivered"`
}

func (h *Handler) ChangeStatus(c *gin.Context) {
	orderID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Sargyt ID-si nädogry"})
		return
	}
	var req statusRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	err = h.service.ChangeStatus(c.Request.Context(), orderID, middleware.Current(c).UserID, req.Status)
	if errors.Is(err, ErrInvalidTransition) {
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ýagdaý üýtgedilmedi"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"id": orderID, "status": req.Status})
}
