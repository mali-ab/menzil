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
	clientID := middleware.Current(c).UserID
	id, err := h.service.Create(c.Request.Context(), clientID, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Sargyt döredilmedi"})
		return
	}
	code, err := h.service.PrepareEscrowAndOTP(c.Request.Context(), id, clientID, req.PriceAmount)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Eskrou ýa-da OTP döredilmedi"})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"id": id, "status": "created", "delivery_code": code})
}

func (h *Handler) Available(c *gin.Context) {
	orders, err := h.service.Available(c.Request.Context(), middleware.Current(c).UserID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Sargytlaryň sanawy alynmady"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"items": orders})
}

func (h *Handler) Active(c *gin.Context) {
	orders, err := h.service.Active(c.Request.Context(), middleware.Current(c).UserID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Aktiw sargytlar alynmady"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"items": orders})
}

func (h *Handler) Mine(c *gin.Context) {
	principal := middleware.Current(c)
	orders, err := h.service.Mine(c.Request.Context(), principal.UserID, principal.Role)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Sargytlaryňyz alynmady"})
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

type otpRequest struct { Code string `json:"code" binding:"required,len=6"` }
type photoProofRequest struct { PhotoURL string `json:"photo_url" binding:"required,url,max=2000"` }

func (h *Handler) VerifyOTP(c *gin.Context) {
	orderID, err := uuid.Parse(c.Param("id"))
	if err != nil { c.JSON(http.StatusBadRequest, gin.H{"error": "Sargyt ID-si nädogry"}); return }
	var req otpRequest
	if err := c.ShouldBindJSON(&req); err != nil { c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()}); return }
	err = h.service.VerifyOTP(c.Request.Context(), orderID, middleware.Current(c).UserID, req.Code)
	if errors.Is(err, ErrProofInvalid) || errors.Is(err, ErrInvalidTransition) { c.JSON(http.StatusConflict, gin.H{"error": err.Error()}); return }
	if err != nil { c.JSON(http.StatusInternalServerError, gin.H{"error": "OTP tassyklanylmady"}); return }
	c.JSON(http.StatusOK, gin.H{"id": orderID, "status": "delivered", "escrow_status": "released"})
}

func (h *Handler) SubmitPhoto(c *gin.Context) {
	orderID, err := uuid.Parse(c.Param("id"))
	if err != nil { c.JSON(http.StatusBadRequest, gin.H{"error": "Sargyt ID-si nädogry"}); return }
	var req photoProofRequest
	if err := c.ShouldBindJSON(&req); err != nil { c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()}); return }
	err = h.service.SubmitPhoto(c.Request.Context(), orderID, middleware.Current(c).UserID, req.PhotoURL)
	if errors.Is(err, ErrInvalidTransition) { c.JSON(http.StatusConflict, gin.H{"error": err.Error()}); return }
	if err != nil { c.JSON(http.StatusInternalServerError, gin.H{"error": "Foto subutnamasy kabul edilmedi"}); return }
	c.JSON(http.StatusOK, gin.H{"id": orderID, "status": "delivered", "escrow_status": "released"})
}
