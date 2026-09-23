package tracking

import (
	"sync"

	"github.com/google/uuid"
)

// Hub diňe bir API instance üçin abonentleri saklaýar. Gorizontal ulalanda
// Redis Pub/Sub bu habarlary beýleki instance-lara hem paýlamaly.
type Hub struct {
	mu          sync.RWMutex
	subscribers map[uuid.UUID]map[chan Location]struct{}
}

func NewHub() *Hub { return &Hub{subscribers: make(map[uuid.UUID]map[chan Location]struct{})} }

func (h *Hub) Subscribe(orderID uuid.UUID) (<-chan Location, func()) {
	ch := make(chan Location, 8)
	h.mu.Lock()
	if h.subscribers[orderID] == nil { h.subscribers[orderID] = make(map[chan Location]struct{}) }
	h.subscribers[orderID][ch] = struct{}{}
	h.mu.Unlock()
	return ch, func() {
		h.mu.Lock()
		delete(h.subscribers[orderID], ch)
		if len(h.subscribers[orderID]) == 0 { delete(h.subscribers, orderID) }
		close(ch)
		h.mu.Unlock()
	}
}

func (h *Hub) Publish(orderID uuid.UUID, location Location) {
	h.mu.RLock()
	defer h.mu.RUnlock()
	for ch := range h.subscribers[orderID] {
		select { case ch <- location: default: }
	}
}
