package auth

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/crypto/bcrypt"
)

type Handler struct {
	db         *pgxpool.Pool
	tokens     *TokenManager
	refreshTTL time.Duration
}

func NewHandler(db *pgxpool.Pool, tokens *TokenManager, refreshTTL time.Duration) *Handler {
	return &Handler{db: db, tokens: tokens, refreshTTL: refreshTTL}
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
	accessToken, err := h.tokens.Issue(userID, role)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Token döredilmedi"})
		return
	}
	refreshToken, err := newRefreshToken()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Täzelenme tokeni döredilmedi"})
		return
	}
	if _, err = h.db.Exec(c.Request.Context(), `
		INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
		VALUES ($1, $2, $3)`, userID, hashRefreshToken(refreshToken), time.Now().Add(h.refreshTTL)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Täzelenme tokeni saklanylmady"})
		return
	}
	h.respondWithTokens(c, accessToken, refreshToken, userID, role)
}

type refreshRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

func (h *Handler) Refresh(c *gin.Context) {
	var req refreshRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
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
	var role string
	err = tx.QueryRow(ctx, `
		SELECT rt.user_id, ur.role_code
		FROM refresh_tokens rt
		JOIN users u ON u.id = rt.user_id
		JOIN user_roles ur ON ur.user_id = rt.user_id
		WHERE rt.token_hash = $1 AND rt.revoked_at IS NULL
		  AND rt.expires_at > now() AND u.is_active = TRUE
		LIMIT 1 FOR UPDATE OF rt`, hashRefreshToken(req.RefreshToken)).Scan(&userID, &role)
	if errors.Is(err, pgx.ErrNoRows) {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Täzelenme tokeni nädogry ýa-da möhleti gutardy"})
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ulgam säwligi"})
		return
	}

	accessToken, err := h.tokens.Issue(userID, role)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Token döredilmedi"})
		return
	}
	refreshToken, err := newRefreshToken()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Täzelenme tokeni döredilmedi"})
		return
	}
	if _, err = tx.Exec(ctx, `UPDATE refresh_tokens SET revoked_at = now() WHERE token_hash = $1`, hashRefreshToken(req.RefreshToken)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Token täzelenmedi"})
		return
	}
	if _, err = tx.Exec(ctx, `
		INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
		VALUES ($1, $2, $3)`, userID, hashRefreshToken(refreshToken), time.Now().Add(h.refreshTTL)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Token täzelenmedi"})
		return
	}
	if err = tx.Commit(ctx); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Token täzelenmedi"})
		return
	}
	h.respondWithTokens(c, accessToken, refreshToken, userID, role)
}

func newRefreshToken() (string, error) {
	raw := make([]byte, 32)
	if _, err := rand.Read(raw); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(raw), nil
}

func hashRefreshToken(token string) string {
	hash := sha256.Sum256([]byte(token))
	return hex.EncodeToString(hash[:])
}

func (h *Handler) respondWithTokens(c *gin.Context, accessToken, refreshToken string, userID uuid.UUID, role string) {
	c.JSON(http.StatusOK, gin.H{
		"access_token": accessToken,
		"refresh_token": refreshToken,
		"token_type":   "Bearer",
		"user_id":      userID,
		"role":         role,
	})
}
