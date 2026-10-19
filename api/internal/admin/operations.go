package admin

import (
	"errors"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"menzil/internal/middleware"
)

type createOrderRequest struct {
	ClientPhone      string  `json:"client_phone" binding:"required"`
	Title            string  `json:"title" binding:"required,max=180"`
	Description      string  `json:"description"`
	Transport        string  `json:"transport" binding:"required,oneof=foot bicycle scooter car truck"`
	PickupAddress    string  `json:"pickup_address" binding:"required"`
	DeliveryAddress  string  `json:"delivery_address" binding:"required"`
	DeliveryPhone    string  `json:"delivery_phone" binding:"required"`
	Price            float64 `json:"price" binding:"gte=0"`
}

func (h *Handler) Orders(c *gin.Context) {
	rows, err := h.db.Query(c, `
		SELECT o.id, o.public_number, o.title, COALESCE(o.description,''), o.status_code,
		       o.pickup_address, o.delivery_address, o.price_amount, o.currency,
		       o.required_transport_code, o.created_at, cu.full_name,
		       COALESCE(co.full_name,''), COALESCE(o.courier_id::text,''),
		       ST_Y(o.pickup_location::geometry), ST_X(o.pickup_location::geometry),
		       ST_Y(o.delivery_location::geometry), ST_X(o.delivery_location::geometry)
		FROM orders o
		JOIN users cu ON cu.id=o.client_id
		LEFT JOIN users co ON co.id=o.courier_id
		ORDER BY o.created_at DESC`)
	if err != nil { c.JSON(http.StatusInternalServerError, gin.H{"error": "Sargytlar alynmady"}); return }
	defer rows.Close()
	items := make([]gin.H, 0)
	for rows.Next() {
		var id uuid.UUID
		var number int64
		var title, description, status, pickup, delivery, currency, transport, client, courier, courierID string
		var price float64
		var pickupLatitude, pickupLongitude, deliveryLatitude, deliveryLongitude float64
		var createdAt any
		if err := rows.Scan(&id, &number, &title, &description, &status, &pickup, &delivery, &price, &currency, &transport, &createdAt, &client, &courier, &courierID, &pickupLatitude, &pickupLongitude, &deliveryLatitude, &deliveryLongitude); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Sargytlar okalmady"}); return
		}
		items = append(items, gin.H{"id": id, "public_number": number, "title": title, "description": description, "status": status, "pickup_address": pickup, "delivery_address": delivery, "price": price, "currency": currency, "transport": transport, "created_at": createdAt, "client": client, "courier": courier, "courier_id": courierID, "pickup_latitude": pickupLatitude, "pickup_longitude": pickupLongitude, "delivery_latitude": deliveryLatitude, "delivery_longitude": deliveryLongitude})
	}
	if err := rows.Err(); err != nil { c.JSON(http.StatusInternalServerError, gin.H{"error": "Sargytlar okalmady"}); return }
	c.JSON(http.StatusOK, gin.H{"items": items})
}

func (h *Handler) CreateOrder(c *gin.Context) {
	var req createOrderRequest
	if err := c.ShouldBindJSON(&req); err != nil { c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()}); return }
	var clientID uuid.UUID
	var clientName string
	err := h.db.QueryRow(c, `SELECT cp.user_id,u.full_name FROM client_profiles cp JOIN users u ON u.id=cp.user_id WHERE u.phone=$1 AND u.is_active`, req.ClientPhone).Scan(&clientID, &clientName)
	if errors.Is(err, pgx.ErrNoRows) { c.JSON(http.StatusNotFound, gin.H{"error": "Client with this phone was not found"}); return }
	if err != nil { c.JSON(http.StatusInternalServerError, gin.H{"error": "Client lookup failed"}); return }
	var id uuid.UUID
	var number int64
	err = h.db.QueryRow(c, `INSERT INTO orders (
		client_id,required_transport_code,title,description,weight_kg,length_cm,width_cm,height_cm,
		pickup_address,pickup_location,pickup_contact_name,pickup_contact_phone,
		delivery_address,delivery_location,delivery_contact_name,delivery_contact_phone,price_amount
	) VALUES ($1,$2,$3,$4,1,20,20,20,$5,ST_SetSRID(ST_MakePoint(58.3834,37.9396),4326)::geography,$6,$7,
		$8,ST_SetSRID(ST_MakePoint(58.3610,37.9282),4326)::geography,'Recipient',$9,$10)
	RETURNING id,public_number`, clientID, req.Transport, req.Title, req.Description, req.PickupAddress, clientName, req.ClientPhone, req.DeliveryAddress, req.DeliveryPhone, req.Price).Scan(&id, &number)
	if err != nil { c.JSON(http.StatusInternalServerError, gin.H{"error": "Order could not be created"}); return }
	_, _ = h.db.Exec(c, `INSERT INTO order_status_history(order_id,status_code,actor_user_id) VALUES($1,'created',$2)`, id, middleware.Current(c).UserID)
	c.JSON(http.StatusCreated, gin.H{"id": id, "public_number": number, "status": "created"})
}

type orderStatusRequest struct { Status string `json:"status" binding:"required,oneof=created accepted to_pickup delivering delivered cancelled"` }

func (h *Handler) SetOrderStatus(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id")); if err != nil { c.JSON(http.StatusBadRequest, gin.H{"error":"Invalid order ID"}); return }
	var req orderStatusRequest
	if err := c.ShouldBindJSON(&req); err != nil { c.JSON(http.StatusBadRequest, gin.H{"error":err.Error()}); return }
	command, err := h.db.Exec(c, `UPDATE orders SET status_code=$2,
		delivered_at=CASE WHEN $2='delivered' THEN now() ELSE delivered_at END,
		cancelled_at=CASE WHEN $2='cancelled' THEN now() ELSE cancelled_at END
		WHERE id=$1 AND (courier_id IS NOT NULL OR $2 IN ('created','cancelled'))`, id, req.Status)
	if err != nil { c.JSON(http.StatusInternalServerError, gin.H{"error":"Order status was not updated"}); return }
	if command.RowsAffected()==0 { c.JSON(http.StatusConflict, gin.H{"error":"Assign a courier before activating this order"}); return }
	_, _ = h.db.Exec(c, `INSERT INTO order_status_history(order_id,status_code,actor_user_id) VALUES($1,$2,$3)`, id, req.Status, middleware.Current(c).UserID)
	c.JSON(http.StatusOK, gin.H{"id":id,"status":req.Status})
}

type assignCourierRequest struct { CourierID uuid.UUID `json:"courier_id" binding:"required"` }

func (h *Handler) AssignCourier(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id")); if err != nil { c.JSON(http.StatusBadRequest, gin.H{"error":"Invalid order ID"}); return }
	var req assignCourierRequest
	if err := c.ShouldBindJSON(&req); err != nil { c.JSON(http.StatusBadRequest, gin.H{"error":err.Error()}); return }
	command, err := h.db.Exec(c, `UPDATE orders o SET courier_id=$2,status_code='accepted',accepted_at=COALESCE(accepted_at,now()) FROM courier_profiles cp WHERE o.id=$1 AND cp.user_id=$2`, id, req.CourierID)
	if err != nil { c.JSON(http.StatusInternalServerError, gin.H{"error":"Courier was not assigned"}); return }
	if command.RowsAffected()==0 { c.JSON(http.StatusNotFound, gin.H{"error":"Order or courier was not found"}); return }
	_, _ = h.db.Exec(c, `INSERT INTO order_status_history(order_id,status_code,actor_user_id) VALUES($1,'accepted',$2)`, id, middleware.Current(c).UserID)
	c.JSON(http.StatusOK, gin.H{"id":id,"courier_id":req.CourierID,"status":"accepted"})
}

func (h *Handler) Couriers(c *gin.Context) {
	rows, err := h.db.Query(c, `SELECT cp.user_id,u.full_name,cp.transport_type_code,cp.is_available,cp.rating,
		(SELECT count(*) FROM orders o WHERE o.courier_id=cp.user_id AND o.status_code IN ('accepted','to_pickup','delivering')),
		ST_Y(clc.location::geometry), ST_X(clc.location::geometry), clc.recorded_at
		FROM courier_profiles cp
		JOIN users u ON u.id=cp.user_id
		LEFT JOIN courier_location_current clc ON clc.courier_id=cp.user_id
		ORDER BY cp.is_available DESC,u.full_name`)
	if err != nil { c.JSON(http.StatusInternalServerError, gin.H{"error":"Couriers could not be loaded"}); return }
	defer rows.Close()
	items:=make([]gin.H,0)
	for rows.Next(){ var id uuid.UUID; var name,transport string; var available bool; var rating float64; var active int64; var latitude,longitude *float64; var recordedAt *time.Time; if err:=rows.Scan(&id,&name,&transport,&available,&rating,&active,&latitude,&longitude,&recordedAt); err!=nil { c.JSON(500,gin.H{"error":"Couriers could not be read"}); return }; items=append(items,gin.H{"id":id,"name":name,"transport":transport,"is_available":available,"rating":rating,"active_orders":active,"latitude":latitude,"longitude":longitude,"location_recorded_at":recordedAt}) }
	c.JSON(http.StatusOK,gin.H{"items":items})
}

type courierAvailabilityRequest struct { IsAvailable bool `json:"is_available"` }

func (h *Handler) SetCourierAvailability(c *gin.Context) {
	id,err:=uuid.Parse(c.Param("id")); if err!=nil { c.JSON(400,gin.H{"error":"Invalid courier ID"}); return }
	var req courierAvailabilityRequest; if err:=c.ShouldBindJSON(&req); err!=nil { c.JSON(400,gin.H{"error":err.Error()}); return }
	command,err:=h.db.Exec(c,`UPDATE courier_profiles SET is_available=$2 WHERE user_id=$1`,id,req.IsAvailable)
	if err!=nil { c.JSON(500,gin.H{"error":"Courier availability was not updated"}); return }; if command.RowsAffected()==0 { c.JSON(404,gin.H{"error":"Courier was not found"}); return }
	c.JSON(200,gin.H{"id":id,"is_available":req.IsAvailable})
}
