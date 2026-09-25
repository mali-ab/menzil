package orders

import "github.com/google/uuid"

type CreateRequest struct {
	Title                 string  `json:"title" binding:"required,max=180"`
	Description           string  `json:"description"`
	RequiredTransportCode string  `json:"required_transport" binding:"required,oneof=foot bicycle scooter car truck"`
	WeightKg              float64 `json:"weight_kg" binding:"required,gt=0"`
	LengthCm              float64 `json:"length_cm" binding:"required,gt=0"`
	WidthCm               float64 `json:"width_cm" binding:"required,gt=0"`
	HeightCm              float64 `json:"height_cm" binding:"required,gt=0"`
	PickupAddress         string  `json:"pickup_address" binding:"required"`
	PickupLatitude        float64 `json:"pickup_latitude" binding:"required,latitude"`
	PickupLongitude       float64 `json:"pickup_longitude" binding:"required,longitude"`
	PickupContactName     string  `json:"pickup_contact_name" binding:"required,max=160"`
	PickupContactPhone    string  `json:"pickup_contact_phone" binding:"required,max=32"`
	DeliveryAddress       string  `json:"delivery_address" binding:"required"`
	DeliveryLatitude      float64 `json:"delivery_latitude" binding:"required,latitude"`
	DeliveryLongitude     float64 `json:"delivery_longitude" binding:"required,longitude"`
	DeliveryContactName   string  `json:"delivery_contact_name" binding:"required,max=160"`
	DeliveryContactPhone  string  `json:"delivery_contact_phone" binding:"required,max=32"`
	PriceAmount           float64 `json:"price_amount" binding:"gte=0"`
}

type AvailableOrder struct {
	ID                    uuid.UUID `json:"id"`
	PublicNumber          int64     `json:"public_number"`
	Title                 string    `json:"title"`
	WeightKg              float64   `json:"weight_kg"`
	RequiredTransportCode string    `json:"required_transport"`
	Status                string    `json:"status"`
	PickupAddress         string    `json:"pickup_address"`
	PickupLatitude        float64   `json:"pickup_latitude"`
	PickupLongitude       float64   `json:"pickup_longitude"`
	DeliveryAddress       string    `json:"delivery_address"`
	DeliveryLatitude      float64   `json:"delivery_latitude"`
	DeliveryLongitude     float64   `json:"delivery_longitude"`
	PriceAmount           float64   `json:"price_amount"`
}
