package middleware

import "github.com/gin-gonic/gin"

// Development üçin browser client-iň API-a ýüz tutmagyna rugsat berýär.
// Önümçilikde Access-Control-Allow-Origin anyk web domenleriniň allowlist-i
// bilen çalşylmaly.
func CORS() gin.HandlerFunc {
	return func(c *gin.Context) {
		origin := c.GetHeader("Origin")
		if origin != "" {
			c.Header("Access-Control-Allow-Origin", origin)
			c.Header("Vary", "Origin")
		}
		c.Header("Access-Control-Allow-Headers", "Authorization, Content-Type")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, OPTIONS")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	}
}
