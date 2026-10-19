package profile

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"

	"menzil/internal/middleware"
)

type Handler struct{ db *pgxpool.Pool }

func NewHandler(db *pgxpool.Pool) *Handler { return &Handler{db: db} }

func (h *Handler) Get(c *gin.Context) {
	principal := middleware.Current(c)
	ctx := c.Request.Context()
	var name, phone, transport string
	err := h.db.QueryRow(ctx, `SELECT u.full_name,u.phone,COALESCE(cp.transport_type_code,'') FROM users u LEFT JOIN courier_profiles cp ON cp.user_id=u.id WHERE u.id=$1`, principal.UserID).Scan(&name, &phone, &transport)
	if err != nil { c.JSON(http.StatusInternalServerError, gin.H{"error": "Profil alynmady"}); return }
	c.JSON(http.StatusOK, gin.H{"full_name": name, "phone": phone, "role": principal.Role, "transport": transport})
}

type updateRequest struct {
	FullName  string `json:"full_name" binding:"required,max=160"`
	Transport string `json:"transport" binding:"omitempty,oneof=foot bicycle scooter car truck"`
}

func (h *Handler) Update(c *gin.Context) {
	principal := middleware.Current(c)
	ctx := c.Request.Context()
	var req updateRequest
	if err := c.ShouldBindJSON(&req); err != nil { c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()}); return }
	tx, err := h.db.Begin(ctx)
	if err != nil { c.JSON(http.StatusInternalServerError, gin.H{"error": "Profil täzelenmedi"}); return }
	defer tx.Rollback(ctx)
	if _, err = tx.Exec(ctx, `UPDATE users SET full_name=$2 WHERE id=$1`, principal.UserID, req.FullName); err != nil { c.JSON(http.StatusInternalServerError, gin.H{"error": "Profil täzelenmedi"}); return }
	if principal.Role == "courier" && req.Transport != "" {
		if _, err = tx.Exec(ctx, `UPDATE courier_profiles SET transport_type_code=$2 WHERE user_id=$1`, principal.UserID, req.Transport); err != nil { c.JSON(http.StatusInternalServerError, gin.H{"error": "Ulag görnüşi täzelenmedi"}); return }
	}
	if err = tx.Commit(ctx); err != nil { c.JSON(http.StatusInternalServerError, gin.H{"error": "Profil täzelenmedi"}); return }
	c.JSON(http.StatusOK, gin.H{"full_name": req.FullName, "phone": "", "role": principal.Role, "transport": req.Transport})
}
