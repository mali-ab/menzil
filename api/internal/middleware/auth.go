package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"

	"menzil/internal/auth"
)

const principalKey = "principal"

func Authenticate(tokens *auth.TokenManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		header := c.GetHeader("Authorization")
		parts := strings.SplitN(header, " ", 2)
		rawToken := ""
		if len(parts) == 2 && strings.EqualFold(parts[0], "Bearer") {
			rawToken = parts[1]
		} else if strings.HasSuffix(c.Request.URL.Path, "/ws") {
			// Browser WebSocket API custom Authorization header ibermeýär.
			// Şeýlelikde diňe WS birikmeleri üçin token query parametrinden alynýar.
			rawToken = c.Query("access_token")
		}
		if rawToken == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Bearer token gerek"})
			return
		}
		principal, err := tokens.Parse(rawToken)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Token nädogry ýa-da möhleti gutardy"})
			return
		}
		c.Set(principalKey, principal)
		c.Next()
	}
}

func RequireRole(role string) gin.HandlerFunc {
	return func(c *gin.Context) {
		principal := Current(c)
		if principal.Role != role {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{"error": "Bu amal üçin rugsat ýok"})
			return
		}
		c.Next()
	}
}

func Current(c *gin.Context) auth.Principal {
	principal, _ := c.Get(principalKey)
	return principal.(auth.Principal)
}
