package orders

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"math/big"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/crypto/bcrypt"
)

var ErrUnavailable = errors.New("sargyt elýeterli däl")
var ErrCapacity = errors.New("kurýeriň aktiw sargyt çägi doldy")
var ErrInvalidTransition = errors.New("ýagdaý geçişi rugsat edilmeýär")
var ErrProofInvalid = errors.New("eltiriş kody nädogry ýa-da möhleti gutardy")

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
		SELECT o.id, o.public_number, o.title, o.weight_kg, o.required_transport_code, o.status_code,
		       o.pickup_address, ST_Y(o.pickup_location::geometry), ST_X(o.pickup_location::geometry), o.delivery_address,
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
		if err := rows.Scan(&row.ID, &row.PublicNumber, &row.Title, &row.WeightKg, &row.RequiredTransportCode, &row.Status, &row.PickupAddress, &row.PickupLatitude, &row.PickupLongitude, &row.DeliveryAddress, &row.DeliveryLatitude, &row.DeliveryLongitude, &row.PriceAmount); err != nil { return nil, err }
		result = append(result, row)
	}
	return result, rows.Err()
}

func (s *Service) Active(ctx context.Context, courierID uuid.UUID) ([]AvailableOrder, error) {
	const q = `
		SELECT o.id, o.public_number, o.title, o.weight_kg, o.required_transport_code, o.status_code,
		       o.pickup_address, ST_Y(o.pickup_location::geometry), ST_X(o.pickup_location::geometry), o.delivery_address,
		       ST_Y(o.delivery_location::geometry), ST_X(o.delivery_location::geometry), o.price_amount
		FROM orders o
		WHERE o.courier_id = $1 AND o.status_code IN ('accepted', 'to_pickup', 'delivering')
		ORDER BY o.accepted_at ASC`
	return scanOrders(ctx, s.db, q, courierID)
}

func (s *Service) Mine(ctx context.Context, userID uuid.UUID, role string) ([]AvailableOrder, error) {
	column := "client_id"
	if role == "courier" {
		column = "courier_id"
	}
	query := `
		SELECT o.id, o.public_number, o.title, o.weight_kg, o.required_transport_code, o.status_code,
		       o.pickup_address, ST_Y(o.pickup_location::geometry), ST_X(o.pickup_location::geometry), o.delivery_address,
		       ST_Y(o.delivery_location::geometry), ST_X(o.delivery_location::geometry), o.price_amount
		FROM orders o
		WHERE o.` + column + ` = $1
		ORDER BY o.created_at DESC`
	return scanOrders(ctx, s.db, query, userID)
}

func (s *Service) PrepareEscrowAndOTP(ctx context.Context, orderID, clientID uuid.UUID, amount float64) (string, error) {
	value, err := rand.Int(rand.Reader, big.NewInt(1000000))
	if err != nil { return "", err }
	code := fmt.Sprintf("%06d", value.Int64())
	hash, err := bcrypt.GenerateFromPassword([]byte(code), bcrypt.DefaultCost)
	if err != nil { return "", err }
	tx, err := s.db.Begin(ctx)
	if err != nil { return "", err }
	defer tx.Rollback(ctx)
	_, err = tx.Exec(ctx, `INSERT INTO delivery_proofs(order_id, otp_hash, otp_expires_at) VALUES($1,$2,now() + interval '24 hours')`, orderID, string(hash))
	if err != nil { return "", err }
	if amount > 0 {
		_, err = tx.Exec(ctx, `INSERT INTO escrow_transactions(order_id,client_id,amount,currency,status,provider,held_at) VALUES($1,$2,$3,'TMT','held','development',now())`, orderID, clientID, amount)
		if err != nil { return "", err }
	}
	if err = tx.Commit(ctx); err != nil { return "", err }
	return code, nil
}

func (s *Service) VerifyOTP(ctx context.Context, orderID, courierID uuid.UUID, code string) error {
	var hash string
	err := s.db.QueryRow(ctx, `SELECT p.otp_hash FROM delivery_proofs p JOIN orders o ON o.id=p.order_id WHERE p.order_id=$1 AND o.courier_id=$2 AND o.status_code='delivering' AND p.otp_expires_at > now()`, orderID, courierID).Scan(&hash)
	if errors.Is(err, pgx.ErrNoRows) || bcrypt.CompareHashAndPassword([]byte(hash), []byte(code)) != nil { return ErrProofInvalid }
	if err != nil { return err }
	return s.finishDelivery(ctx, orderID, courierID, `UPDATE delivery_proofs SET otp_verified_at=now(), verified_by_user_id=$2 WHERE order_id=$1`, nil)
}

func (s *Service) SubmitPhoto(ctx context.Context, orderID, courierID uuid.UUID, photoURL string) error {
	return s.finishDelivery(ctx, orderID, courierID, `UPDATE delivery_proofs SET photo_url=$3, photo_uploaded_at=now(), verified_by_user_id=$2 WHERE order_id=$1`, []any{photoURL})
}

func (s *Service) finishDelivery(ctx context.Context, orderID, courierID uuid.UUID, proofQuery string, proofArgs []any) error {
	tx, err := s.db.Begin(ctx)
	if err != nil { return err }
	defer tx.Rollback(ctx)
	args := []any{orderID, courierID}
	args = append(args, proofArgs...)
	if _, err = tx.Exec(ctx, proofQuery, args...); err != nil { return err }
	var updated uuid.UUID
	err = tx.QueryRow(ctx, `UPDATE orders SET status_code='delivered', delivered_at=now() WHERE id=$1 AND courier_id=$2 AND status_code='delivering' RETURNING id`, orderID, courierID).Scan(&updated)
	if errors.Is(err, pgx.ErrNoRows) { return ErrInvalidTransition }
	if err != nil { return err }
	if _, err = tx.Exec(ctx, `UPDATE escrow_transactions SET courier_id=$2,status='released',released_at=now() WHERE order_id=$1 AND status='held'`, orderID, courierID); err != nil { return err }
	if _, err = tx.Exec(ctx, `INSERT INTO order_status_history(order_id,status_code,actor_user_id) VALUES($1,'delivered',$2)`, orderID, courierID); err != nil { return err }
	return tx.Commit(ctx)
}

type rowQuerier interface {
	Query(context.Context, string, ...any) (pgx.Rows, error)
}

func scanOrders(ctx context.Context, db rowQuerier, query string, args ...any) ([]AvailableOrder, error) {
	rows, err := db.Query(ctx, query, args...)
	if err != nil { return nil, err }
	defer rows.Close()
	result := make([]AvailableOrder, 0)
	for rows.Next() {
		var row AvailableOrder
		if err := rows.Scan(&row.ID, &row.PublicNumber, &row.Title, &row.WeightKg, &row.RequiredTransportCode, &row.Status, &row.PickupAddress, &row.PickupLatitude, &row.PickupLongitude, &row.DeliveryAddress, &row.DeliveryLatitude, &row.DeliveryLongitude, &row.PriceAmount); err != nil { return nil, err }
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
