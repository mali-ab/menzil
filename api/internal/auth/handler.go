package auth

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/crypto/bcrypt"
)

type Handler struct {
	db     *pgxpool.Pool
	tokens *TokenManager
}

func NewHandler(db *pgxpool.Pool, tokens *TokenManager) *Handler {
	return &Handler{db: db, tokens: tokens}
}

type registerRequest struct {
	Phone     string `json:"phone" binding:"required,max=32"`
	Email     string `json:"email" binding:"omitempty,email"`
	FullName  string `json:"full_name" binding:"required,max=160"`
	Password  string `json:"password" binding:"required,min=8,max=72"`
	Role      string `json:"role" binding:"required,oneof=client courier"`
	Transport string `json:"transport" binding:"omitempty,oneof=foot bicycle scooter car truck"`
}

func (h *Handler) Register(c *gin.Context) {
	var req registerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if req.Role == "courier" && req.Transport == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Kurýer üçin ulag görnüşi gerek"})
		return
	}

	passwordHash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Paroly gaýtadan işläp bolmady"})
		return
	}

	ctx := c.Request.Context()
	tx, err := h.db.Begin(ctx)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Maglumatlar bazasy elýeterli däl"})
		return
	}
	defer tx.Rollback(ctx)

	var userID uuid.UUID
	err = tx.QueryRow(ctx, `
		INSERT INTO users (phone, email, full_name, password_hash)
		VALUES ($1, NULLIF($2, ''), $3, $4) RETURNING id`,
		req.Phone, req.Email, req.FullName, string(passwordHash),
	).Scan(&userID)
	if err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Telefon ýa-da e-poçta eýýäm bellige alnan"})
		return
	}
	if _, err = tx.Exec(ctx, `INSERT INTO user_roles (user_id, role_code) VALUES ($1, $2)`, userID, req.Role); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Rol saklanylmady"})
		return
	}
	if req.Role == "client" {
		_, err = tx.Exec(ctx, `INSERT INTO client_profiles (user_id) VALUES ($1)`, userID)
	} else {
		_, err = tx.Exec(ctx, `INSERT INTO courier_profiles (user_id, transport_type_code) VALUES ($1, $2)`, userID, req.Transport)
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Profil saklanylmady"})
		return
	}
	if err = tx.Commit(ctx); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Bellige alyş tamamlanmady"})
		return
	}
	h.respondWithToken(c, userID, req.Role)
}

type loginRequest struct {
	Phone    string `json:"phone" binding:"required"`
	Password string `json:"password" binding:"required"`
}

func (h *Handler) Login(c *gin.Context) {
	var req loginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var userID uuid.UUID
	var hash, role string
	err := h.db.QueryRow(c.Request.Context(), `
		SELECT u.id, u.password_hash, ur.role_code
		FROM users u JOIN user_roles ur ON ur.user_id = u.id
		WHERE u.phone = $1 AND u.is_active = TRUE
		LIMIT 1`, req.Phone).Scan(&userID, &hash, &role)
	if errors.Is(err, pgx.ErrNoRows) {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Telefon ýa-da parol nädogry"})
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ulgam säwligi"})
		return
	}
	if bcrypt.CompareHashAndPassword([]byte(hash), []byte(req.Password)) != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Telefon ýa-da parol nädogry"})
		return
	}
	h.respondWithToken(c, userID, role)
}

func (h *Handler) respondWithToken(c *gin.Context, userID uuid.UUID, role string) {
	token, err := h.tokens.Issue(userID, role)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Token döredilmedi"})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"access_token": token,
		"token_type":   "Bearer",
		"user_id":      userID,
		"role":         role,
	})
}
