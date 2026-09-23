package tracking

import (
	"context"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/gorilla/websocket"
	"github.com/jackc/pgx/v5/pgxpool"

	"menzil/internal/middleware"
)

type Location struct {
	Type       string    `json:"type"`
	Latitude   float64   `json:"latitude"`
	Longitude  float64   `json:"longitude"`
	AccuracyM  float64   `json:"accuracy_m"`
	HeadingDeg float64   `json:"heading_deg"`
	SpeedMPS   float64   `json:"speed_mps"`
	RecordedAt time.Time `json:"recorded_at"`
}

type Handler struct {
	db  *pgxpool.Pool
	hub *Hub
	upgrader websocket.Upgrader
}

func NewHandler(db *pgxpool.Pool, hub *Hub) *Handler {
	return &Handler{db: db, hub: hub, upgrader: websocket.Upgrader{
		ReadBufferSize: 1024, WriteBufferSize: 1024,
		CheckOrigin: func(r *http.Request) bool { return true }, // mobil programma üçin origin çäklendirmesi ýok
	}}
}

func (h *Handler) CourierSocket(c *gin.Context) {
	conn, err := h.upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil { return }
	defer conn.Close()
	courierID := middleware.Current(c).UserID
	conn.SetReadLimit(2048)
	for {
		var location Location
		if err := conn.ReadJSON(&location); err != nil { return }
		if location.Type != "location" || location.Latitude < -90 || location.Latitude > 90 || location.Longitude < -180 || location.Longitude > 180 {
			_ = conn.WriteJSON(gin.H{"error": "Geopozisiýa nädogry"})
			continue
		}
		if location.RecordedAt.IsZero() { location.RecordedAt = time.Now().UTC() }
		orderIDs, err := h.save(c.Request.Context(), courierID, location)
		if err != nil { _ = conn.WriteJSON(gin.H{"error": "Pozisiýa saklanylmady"}); continue }
		for _, orderID := range orderIDs { h.hub.Publish(orderID, location) }
		_ = conn.WriteJSON(gin.H{"type": "location_saved", "recorded_at": location.RecordedAt})
	}
}

func (h *Handler) ClientSocket(c *gin.Context) {
	orderID, err := uuid.Parse(c.Param("id"))
	if err != nil { c.JSON(http.StatusBadRequest, gin.H{"error": "Sargyt ID-si nädogry"}); return }
	principal := middleware.Current(c)
	if !h.canTrack(c.Request.Context(), orderID, principal.UserID) { c.JSON(http.StatusForbidden, gin.H{"error": "Rugsat ýok"}); return }
	conn, err := h.upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil { return }
	defer conn.Close()
	updates, unsubscribe := h.hub.Subscribe(orderID)
	defer unsubscribe()
	for update := range updates {
		if err := conn.WriteJSON(update); err != nil { return }
	}
}

func (h *Handler) save(ctx context.Context, courierID uuid.UUID, loc Location) ([]uuid.UUID, error) {
	tx, err := h.db.Begin(ctx)
	if err != nil { return nil, err }
	defer tx.Rollback(ctx)
	const point = `ST_SetSRID(ST_MakePoint($2,$3),4326)::geography`
	_, err = tx.Exec(ctx, `INSERT INTO courier_location_current(courier_id,location,accuracy_m,heading_deg,speed_mps,recorded_at)
		VALUES($1,`+point+`,$4,$5,$6,$7)
		ON CONFLICT(courier_id) DO UPDATE SET location=EXCLUDED.location,accuracy_m=EXCLUDED.accuracy_m,heading_deg=EXCLUDED.heading_deg,speed_mps=EXCLUDED.speed_mps,recorded_at=EXCLUDED.recorded_at,updated_at=now()`,
		courierID, loc.Longitude, loc.Latitude, loc.AccuracyM, loc.HeadingDeg, loc.SpeedMPS, loc.RecordedAt)
	if err != nil { return nil, err }
	_, err = tx.Exec(ctx, `INSERT INTO courier_location_history(courier_id,location,accuracy_m,heading_deg,speed_mps,recorded_at)
		VALUES($1,`+point+`,$4,$5,$6,$7)`, courierID, loc.Longitude, loc.Latitude, loc.AccuracyM, loc.HeadingDeg, loc.SpeedMPS, loc.RecordedAt)
	if err != nil { return nil, err }
	rows, err := tx.Query(ctx, `SELECT id FROM orders WHERE courier_id=$1 AND status_code IN ('accepted','to_pickup','delivering')`, courierID)
	if err != nil { return nil, err }
	defer rows.Close()
	ids := []uuid.UUID{}
	for rows.Next() { var id uuid.UUID; if err := rows.Scan(&id); err != nil { return nil, err }; ids = append(ids, id) }
	if err := rows.Err(); err != nil { return nil, err }
	return ids, tx.Commit(ctx)
}

func (h *Handler) canTrack(ctx context.Context, orderID, userID uuid.UUID) bool {
	var found uuid.UUID
	err := h.db.QueryRow(ctx, `SELECT id FROM orders WHERE id=$1 AND (client_id=$2 OR courier_id=$2)`, orderID, userID).Scan(&found)
	return err == nil && found == orderID
}
