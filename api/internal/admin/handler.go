package admin

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Handler exposes an intentionally small operational overview. Personal phone
// numbers and payment references remain outside this response.
type Handler struct{ db *pgxpool.Pool }

func NewHandler(db *pgxpool.Pool) *Handler { return &Handler{db: db} }

func (h *Handler) Overview(c *gin.Context) {
	ctx := c.Request.Context()
	counts := map[string]int64{}
	for key, query := range map[string]string{
		"clients": "SELECT count(*) FROM client_profiles",
		"couriers": "SELECT count(*) FROM courier_profiles",
		"available_couriers": "SELECT count(*) FROM courier_profiles WHERE is_available",
		"open_orders": "SELECT count(*) FROM orders WHERE status_code IN ('created','accepted','to_pickup','delivering')",
		"delivered_today": "SELECT count(*) FROM orders WHERE status_code='delivered' AND delivered_at >= date_trunc('day', now())",
		"complaints": "SELECT 0", // A complaint workflow can replace this when support tickets are enabled.
	} {
		var count int64
		if err := h.db.QueryRow(ctx, query).Scan(&count); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Dolandyryş maglumatlary alynmady"})
			return
		}
		counts[key] = count
	}
	c.JSON(http.StatusOK, counts)
}
