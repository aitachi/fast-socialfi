// Author: Aitachi
// Email: 44158892@qq.com
// Date: 11-02-2025 17

package middleware

import (
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"golang.org/x/time/rate"
)

// RateLimiter handles rate limiting
type RateLimiter struct {
	limiters map[string]*rate.Limiter
	mu       sync.RWMutex
	r        rate.Limit
	b        int
}

// NewRateLimiter creates a new rate limiter
// r is the rate (requests per second)
// b is the burst size
func NewRateLimiter(r rate.Limit, b int) *RateLimiter {
	return &RateLimiter{
		limiters: make(map[string]*rate.Limiter),
		r:        r,
		b:        b,
	}
}

// getLimiter retrieves or creates a limiter for an identifier
func (rl *RateLimiter) getLimiter(identifier string) *rate.Limiter {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	limiter, exists := rl.limiters[identifier]
	if !exists {
		limiter = rate.NewLimiter(rl.r, rl.b)
		rl.limiters[identifier] = limiter
	}

	return limiter
}

// Limit returns a middleware that limits requests
func (rl *RateLimiter) Limit() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Use IP address as identifier
		identifier := c.ClientIP()

		// Check if user is authenticated, use user address instead
		if userAddress, exists := c.Get("user_address"); exists {
			identifier = userAddress.(string)
		}

		limiter := rl.getLimiter(identifier)

		if !limiter.Allow() {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error":   "Rate limit exceeded",
				"message": "Too many requests. Please try again later.",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// CleanupLimiters periodically removes inactive limiters
func (rl *RateLimiter) CleanupLimiters(interval time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	for range ticker.C {
		rl.mu.Lock()
		for key := range rl.limiters {
			// Remove limiters that haven't been used
			delete(rl.limiters, key)
		}
		rl.mu.Unlock()
	}
}

// CustomRateLimit allows different limits for different routes
type CustomRateLimit struct {
	global      *RateLimiter
	routeLimits map[string]*RateLimiter
}

// NewCustomRateLimit creates a new custom rate limiter
func NewCustomRateLimit(globalRate rate.Limit, globalBurst int) *CustomRateLimit {
	return &CustomRateLimit{
		global:      NewRateLimiter(globalRate, globalBurst),
		routeLimits: make(map[string]*RateLimiter),
	}
}

// SetRouteLimit sets a specific limit for a route
func (crl *CustomRateLimit) SetRouteLimit(route string, r rate.Limit, b int) {
	crl.routeLimits[route] = NewRateLimiter(r, b)
}

// Limit returns the rate limit middleware
func (crl *CustomRateLimit) Limit() gin.HandlerFunc {
	return func(c *gin.Context) {
		route := c.FullPath()

		// Check if route has custom limit
		limiter, exists := crl.routeLimits[route]
		if !exists {
			limiter = crl.global
		}

		identifier := c.ClientIP()
		if userAddress, exists := c.Get("user_address"); exists {
			identifier = userAddress.(string)
		}

		rl := limiter.getLimiter(identifier)

		if !rl.Allow() {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error":   "Rate limit exceeded",
				"message": "Too many requests. Please try again later.",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}
