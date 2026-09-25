package communication

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"menzil/internal/middleware"
)

type Handler struct{ db *pgxpool.Pool }
func NewHandler(db *pgxpool.Pool) *Handler { return &Handler{db: db} }

type message struct { ID uuid.UUID `json:"id"`; SenderID uuid.UUID `json:"sender_id"`; Body string `json:"body"`; SentAt time.Time `json:"sent_at"` }

func (h *Handler) Messages(c *gin.Context) {
	orderID, ok := h.authorizedOrder(c); if !ok { return }
	rows, err := h.db.Query(c.Request.Context(), `SELECT m.id,m.sender_user_id,m.body,m.sent_at FROM order_chat_messages m JOIN order_chat_conversations x ON x.id=m.conversation_id WHERE x.order_id=$1 ORDER BY m.sent_at`, orderID)
	if err != nil { c.JSON(http.StatusInternalServerError, gin.H{"error":"Habarlar alynmady"}); return }
	defer rows.Close(); items := []message{}
	for rows.Next() { var item message; if err := rows.Scan(&item.ID,&item.SenderID,&item.Body,&item.SentAt); err != nil { c.JSON(http.StatusInternalServerError,gin.H{"error":"Habar okalmady"}); return }; items=append(items,item) }
	c.JSON(http.StatusOK, gin.H{"items":items})
}

type sendRequest struct { Body string `json:"body" binding:"required,min=1,max=2000"` }
func (h *Handler) Send(c *gin.Context) {
	orderID, ok := h.authorizedOrder(c); if !ok { return }; var req sendRequest
	if err := c.ShouldBindJSON(&req); err != nil { c.JSON(http.StatusBadRequest,gin.H{"error":err.Error()}); return }
	principal := middleware.Current(c); var conversationID uuid.UUID
	err := h.db.QueryRow(c.Request.Context(), `INSERT INTO order_chat_conversations(order_id) VALUES($1) ON CONFLICT(order_id) DO UPDATE SET order_id=EXCLUDED.order_id RETURNING id`, orderID).Scan(&conversationID)
	if err != nil { c.JSON(http.StatusInternalServerError,gin.H{"error":"Çat açylmady"}); return }
	var item message
	err = h.db.QueryRow(c.Request.Context(), `INSERT INTO order_chat_messages(conversation_id,sender_user_id,body) VALUES($1,$2,$3) RETURNING id,sender_user_id,body,sent_at`,conversationID,principal.UserID,req.Body).Scan(&item.ID,&item.SenderID,&item.Body,&item.SentAt)
	if err != nil { c.JSON(http.StatusInternalServerError,gin.H{"error":"Habar iberilmedi"}); return }; c.JSON(http.StatusCreated,item)
}

func (h *Handler) StartCall(c *gin.Context) {
	orderID, ok := h.authorizedOrder(c); if !ok { return }; principal:=middleware.Current(c); room:=uuid.NewString()
	_,err:=h.db.Exec(c.Request.Context(),`INSERT INTO order_call_sessions(order_id,initiator_user_id,provider,provider_room_id) VALUES($1,$2,'development',$3)`,orderID,principal.UserID,room)
	if err != nil { c.JSON(http.StatusInternalServerError,gin.H{"error":"Jaň sessiýasy döredilmedi"}); return }
	// Provider integrasiýasy bu room ID-ni Signal/Twilio/ýerli VoIP SDK-a geçirýär.
	c.JSON(http.StatusCreated,gin.H{"provider":"development","room_id":room,"expires_in_seconds":900})
}

func (h *Handler) authorizedOrder(c *gin.Context) (uuid.UUID,bool) {
	orderID,err:=uuid.Parse(c.Param("id")); if err != nil { c.JSON(http.StatusBadRequest,gin.H{"error":"Sargyt ID-si nädogry"}); return uuid.Nil,false }
	principal:=middleware.Current(c); var found uuid.UUID
	err=h.db.QueryRow(c.Request.Context(),`SELECT id FROM orders WHERE id=$1 AND (client_id=$2 OR courier_id=$2)`,orderID,principal.UserID).Scan(&found)
	if err==pgx.ErrNoRows { c.JSON(http.StatusForbidden,gin.H{"error":"Rugsat ýok"}); return uuid.Nil,false }
	if err!=nil { c.JSON(http.StatusInternalServerError,gin.H{"error":"Sargyt barlanylmady"}); return uuid.Nil,false }
	return orderID,true
}
