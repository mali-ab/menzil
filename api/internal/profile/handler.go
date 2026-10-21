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
	Role      string `json:"role" binding:"omitempty,oneof=client courier"`
	Transport string `json:"transport" binding:"omitempty,oneof=foot bicycle scooter car truck"`
}

func (h *Handler) Update(c *gin.Context) {
	principal := middleware.Current(c)
	ctx := c.Request.Context()
	var req updateRequest
	if err := c.ShouldBindJSON(&req); err != nil { c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()}); return }
	nextRole := req.Role
	if nextRole == "" { nextRole = principal.Role }
	if principal.Role != "client" && principal.Role != "courier" && req.Role != "" {
		c.JSON(http.StatusForbidden, gin.H{"error": "Bu ulanyjy görnüşini üýtgedip bolmaýar"})
		return
	}
	if principal.Role == "client" && nextRole == "courier" && req.Transport == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Kurýer üçin ulag görnüşini saýlaň"})
		return
	}
	tx, err := h.db.Begin(ctx)
	if err != nil { c.JSON(http.StatusInternalServerError, gin.H{"error": "Profil täzelenmedi"}); return }
	defer tx.Rollback(ctx)
	if principal.Role != "client" && principal.Role != "courier" {
		if _, err = tx.Exec(ctx, `UPDATE users SET full_name=$2 WHERE id=$1`, principal.UserID, req.FullName); err != nil { c.JSON(http.StatusInternalServerError, gin.H{"error": "Profil täzelenmedi"}); return }
		if err = tx.Commit(ctx); err != nil { c.JSON(http.StatusInternalServerError, gin.H{"error": "Profil täzelenmedi"}); return }
		c.JSON(http.StatusOK, gin.H{"full_name": req.FullName, "phone": "", "role": principal.Role, "transport": "", "role_changed": false})
		return
	}
	if principal.Role == "courier" && nextRole == "client" {
		var activeOrders int
		if err = tx.QueryRow(ctx, `SELECT count(*) FROM orders WHERE courier_id=$1 AND status_code IN ('accepted','to_pickup','delivering')`, principal.UserID).Scan(&activeOrders); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Profil täzelenmedi"})
			return
		}
		if activeOrders > 0 {
			c.JSON(http.StatusConflict, gin.H{"error": "Aktiw sargyt gutarmanka müşderi görnüşine geçip bolmaýar"})
			return
		}
	}
	if principal.Role == "client" && nextRole == "courier" {
		var activeOrders int
		if err = tx.QueryRow(ctx, `SELECT count(*) FROM orders WHERE client_id=$1 AND status_code IN ('created','accepted','to_pickup','delivering')`, principal.UserID).Scan(&activeOrders); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Profil täzelenmedi"})
			return
		}
		if activeOrders > 0 {
			c.JSON(http.StatusConflict, gin.H{"error": "Aktiw sargyt gutarmanka kurýer görnüşine geçip bolmaýar"})
			return
		}
	}
	if _, err = tx.Exec(ctx, `UPDATE users SET full_name=$2 WHERE id=$1`, principal.UserID, req.FullName); err != nil { c.JSON(http.StatusInternalServerError, gin.H{"error": "Profil täzelenmedi"}); return }
	if nextRole == "courier" {
		if req.Transport != "" {
			if _, err = tx.Exec(ctx, `INSERT INTO courier_profiles(user_id,transport_type_code) VALUES($1,$2) ON CONFLICT(user_id) DO UPDATE SET transport_type_code=EXCLUDED.transport_type_code`, principal.UserID, req.Transport); err != nil { c.JSON(http.StatusInternalServerError, gin.H{"error": "Ulag görnüşi täzelenmedi"}); return }
		}
	} else {
		if _, err = tx.Exec(ctx, `INSERT INTO client_profiles(user_id) VALUES($1) ON CONFLICT(user_id) DO NOTHING`, principal.UserID); err != nil { c.JSON(http.StatusInternalServerError, gin.H{"error": "Profil täzelenmedi"}); return }
		if _, err = tx.Exec(ctx, `UPDATE courier_profiles SET is_available=FALSE WHERE user_id=$1`, principal.UserID); err != nil { c.JSON(http.StatusInternalServerError, gin.H{"error": "Profil täzelenmedi"}); return }
	}
	if _, err = tx.Exec(ctx, `UPDATE user_roles SET role_code=$2 WHERE user_id=$1`, principal.UserID, nextRole); err != nil { c.JSON(http.StatusInternalServerError, gin.H{"error": "Ulanyjy görnüşi täzelenmedi"}); return }
	if err = tx.Commit(ctx); err != nil { c.JSON(http.StatusInternalServerError, gin.H{"error": "Profil täzelenmedi"}); return }
	c.JSON(http.StatusOK, gin.H{"full_name": req.FullName, "phone": "", "role": nextRole, "transport": req.Transport, "role_changed": nextRole != principal.Role})
}
