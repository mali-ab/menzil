package orders

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var ErrUnavailable = errors.New("sargyt elýeterli däl")
var ErrCapacity = errors.New("kurýeriň aktiw sargyt çägi doldy")
var ErrInvalidTransition = errors.New("ýagdaý geçişi rugsat edilmeýär")

type Service struct{ db *pgxpool.Pool }

func NewService(db *pgxpool.Pool) *Service { return &Service{db: db} }

func (s *Service) Create(ctx context.Context, clientID uuid.UUID, req CreateRequest) (uuid.UUID, error) {
	const q = `
		INSERT INTO orders (
			client_id, required_transport_code, title, description,
			weight_kg, length_cm, width_cm, height_cm,
			pickup_address, pickup_location, pickup_contact_name, pickup_contact_phone,
			delivery_address, delivery_location, delivery_contact_name, delivery_contact_phone,
			price_amount
		) VALUES (
			$1,$2,$3,$4,$5,$6,$7,$8,
			$9,ST_SetSRID(ST_MakePoint($10,$11),4326)::geography,$12,$13,
			$14,ST_SetSRID(ST_MakePoint($15,$16),4326)::geography,$17,$18,$19
		) RETURNING id`
	var id uuid.UUID
	err := s.db.QueryRow(ctx, q,
		clientID, req.RequiredTransportCode, req.Title, req.Description,
		req.WeightKg, req.LengthCm, req.WidthCm, req.HeightCm,
		req.PickupAddress, req.PickupLongitude, req.PickupLatitude, req.PickupContactName, req.PickupContactPhone,
		req.DeliveryAddress, req.DeliveryLongitude, req.DeliveryLatitude, req.DeliveryContactName, req.DeliveryContactPhone,
		req.PriceAmount,
	).Scan(&id)
	return id, err
}

func (s *Service) Available(ctx context.Context, courierID uuid.UUID) ([]AvailableOrder, error) {
	const q = `
		SELECT o.id, o.public_number, o.title, o.weight_kg, o.required_transport_code,
		       o.pickup_address, o.delivery_address,
		       ST_Y(o.delivery_location::geometry), ST_X(o.delivery_location::geometry),
		       o.price_amount
		FROM orders o JOIN courier_profiles cp ON cp.user_id = $1
		WHERE o.status_code = 'created' AND o.courier_id IS NULL
		  AND cp.is_available = TRUE
		  AND o.required_transport_code = cp.transport_type_code
		ORDER BY o.created_at DESC`
	rows, err := s.db.Query(ctx, q, courierID)
	if err != nil { return nil, err }
	defer rows.Close()
	result := make([]AvailableOrder, 0)
	for rows.Next() {
		var row AvailableOrder
		if err := rows.Scan(&row.ID, &row.PublicNumber, &row.Title, &row.WeightKg, &row.RequiredTransportCode, &row.PickupAddress, &row.DeliveryAddress, &row.DeliveryLatitude, &row.DeliveryLongitude, &row.PriceAmount); err != nil { return nil, err }
		result = append(result, row)
	}
	return result, rows.Err()
}

func (s *Service) SetAvailability(ctx context.Context, courierID uuid.UUID, available bool) error {
	command, err := s.db.Exec(ctx, `UPDATE courier_profiles SET is_available = $2 WHERE user_id = $1`, courierID, available)
	if err != nil {
		return err
	}
	if command.RowsAffected() == 0 {
		return ErrUnavailable
	}
	return nil
}

func (s *Service) Accept(ctx context.Context, orderID, courierID uuid.UUID) error {
	tx, err := s.db.Begin(ctx)
	if err != nil { return err }
	defer tx.Rollback(ctx)
	// Şu lock bir kurýeriň parallel kabul ediş request-lerini nobatlaýar.
	// Şeýlelikde aktiw sargytlaryň sany max_active_orders çäginden geçmeýär.
	var lockedCourier uuid.UUID
	if err := tx.QueryRow(ctx, `SELECT user_id FROM courier_profiles WHERE user_id=$1 FOR UPDATE`, courierID).Scan(&lockedCourier); errors.Is(err, pgx.ErrNoRows) {
		return ErrUnavailable
	} else if err != nil {
		return err
	}
	const q = `
		UPDATE orders o SET courier_id=$2, status_code='accepted', accepted_at=now()
		FROM courier_profiles cp
		WHERE o.id=$1 AND cp.user_id=$2 AND cp.is_available=TRUE
		  AND o.courier_id IS NULL AND o.status_code='created'
		  AND o.required_transport_code=cp.transport_type_code
		  AND (SELECT count(*) FROM orders active
		       WHERE active.courier_id=$2
		         AND active.status_code IN ('accepted','to_pickup','delivering')) < cp.max_active_orders
		RETURNING o.id`
	var updated uuid.UUID
	if err := tx.QueryRow(ctx, q, orderID, courierID).Scan(&updated); errors.Is(err, pgx.ErrNoRows) { return ErrCapacity } else if err != nil { return err }
	if _, err = tx.Exec(ctx, `INSERT INTO order_status_history(order_id,status_code,actor_user_id) VALUES($1,'accepted',$2)`, orderID, courierID); err != nil { return err }
	return tx.Commit(ctx)
}

func (s *Service) ChangeStatus(ctx context.Context, orderID, courierID uuid.UUID, next string) error {
	previous := map[string]string{"to_pickup":"accepted", "delivering":"to_pickup", "delivered":"delivering"}[next]
	if previous == "" { return ErrInvalidTransition }
	tx, err := s.db.Begin(ctx)
	if err != nil { return err }
	defer tx.Rollback(ctx)
	const q = `UPDATE orders SET status_code=$3,
		picked_up_at=CASE WHEN $3='delivering' THEN now() ELSE picked_up_at END,
		delivered_at=CASE WHEN $3='delivered' THEN now() ELSE delivered_at END
		WHERE id=$1 AND courier_id=$2 AND status_code=$4 RETURNING id`
	var updated uuid.UUID
	if err := tx.QueryRow(ctx, q, orderID, courierID, next, previous).Scan(&updated); errors.Is(err, pgx.ErrNoRows) { return ErrInvalidTransition } else if err != nil { return err }
	if _, err = tx.Exec(ctx, `INSERT INTO order_status_history(order_id,status_code,actor_user_id) VALUES($1,$2,$3)`, orderID, next, courierID); err != nil { return err }
	return tx.Commit(ctx)
}
