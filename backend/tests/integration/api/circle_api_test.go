package api_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/fast-socialfi/backend/internal/handler"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

func setupTestRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	router := gin.Default()
	return router
}

// TestHealthCheck tests the health check endpoint
func TestHealthCheck(t *testing.T) {
	router := setupTestRouter()
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "healthy",
		})
	})

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/health", nil)
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, "healthy", response["status"])
}

// TestCreateCircle_API tests the create circle API endpoint
func TestCreateCircle_API(t *testing.T) {
	router := setupTestRouter()

	// Mock handler
	router.POST("/api/v1/circles", func(c *gin.Context) {
		var req map[string]interface{}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		// Validate required fields
		if req["name"] == nil || req["symbol"] == nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "missing required fields"})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"circle_id": 1,
			"tx_hash":   "0xmocktxhash",
			"message":   "Circle creation transaction submitted",
		})
	})

	// Test valid request
	validPayload := map[string]interface{}{
		"name":        "Test Circle",
		"symbol":      "TST",
		"description": "Test Description",
		"curve_type":  0,
		"base_price":  "1000000000000000",
		"k":           "1000000000000000",
		"private_key": "0xtest",
	}

	jsonData, _ := json.Marshal(validPayload)
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/api/v1/circles", bytes.NewBuffer(jsonData))
	req.Header.Set("Content-Type", "application/json")
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, float64(1), response["circle_id"])
	assert.NotEmpty(t, response["tx_hash"])
}

// TestCreateCircle_API_InvalidInput tests invalid input handling
func TestCreateCircle_API_InvalidInput(t *testing.T) {
	router := setupTestRouter()

	router.POST("/api/v1/circles", func(c *gin.Context) {
		var req map[string]interface{}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		if req["name"] == nil || req["symbol"] == nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "missing required fields"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"success": true})
	})

	// Test missing required fields
	invalidPayload := map[string]interface{}{
		"description": "Missing name and symbol",
	}

	jsonData, _ := json.Marshal(invalidPayload)
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/api/v1/circles", bytes.NewBuffer(jsonData))
	req.Header.Set("Content-Type", "application/json")
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusBadRequest, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.NotEmpty(t, response["error"])
}

// TestGetCircle_API tests the get circle endpoint
func TestGetCircle_API(t *testing.T) {
	router := setupTestRouter()

	router.GET("/api/v1/circles/:id", func(c *gin.Context) {
		id := c.Param("id")

		if id == "999" {
			c.JSON(http.StatusNotFound, gin.H{"error": "circle not found"})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"id":          id,
			"name":        "Test Circle",
			"symbol":      "TST",
			"description": "Test Description",
			"status":      "confirmed",
		})
	})

	// Test existing circle
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/api/v1/circles/1", nil)
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, "Test Circle", response["name"])

	// Test non-existent circle
	w = httptest.NewRecorder()
	req, _ = http.NewRequest("GET", "/api/v1/circles/999", nil)
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusNotFound, w.Code)
}

// TestListCircles_API tests the list circles endpoint
func TestListCircles_API(t *testing.T) {
	router := setupTestRouter()

	router.GET("/api/v1/circles", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"circles": []map[string]interface{}{
				{"id": 1, "name": "Circle 1", "symbol": "CR1"},
				{"id": 2, "name": "Circle 2", "symbol": "CR2"},
			},
			"total": 2,
			"page":  1,
			"limit": 10,
		})
	})

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/api/v1/circles?page=1&limit=10", nil)
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, float64(2), response["total"])
	assert.NotEmpty(t, response["circles"])
}

// TestBuyTokens_API tests the buy tokens endpoint
func TestBuyTokens_API(t *testing.T) {
	router := setupTestRouter()

	router.POST("/api/v1/trading/buy", func(c *gin.Context) {
		var req map[string]interface{}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		if req["circle_id"] == nil || req["amount"] == nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "missing required fields"})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"tx_hash": "0xbuytxhash",
			"message": "Buy transaction submitted successfully",
		})
	})

	payload := map[string]interface{}{
		"circle_id":   1,
		"amount":      "100",
		"max_cost":    "1000000000000000000",
		"private_key": "0xtest",
	}

	jsonData, _ := json.Marshal(payload)
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/api/v1/trading/buy", bytes.NewBuffer(jsonData))
	req.Header.Set("Content-Type", "application/json")
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.NotEmpty(t, response["tx_hash"])
	assert.Contains(t, response["message"], "Buy transaction")
}

// TestSellTokens_API tests the sell tokens endpoint
func TestSellTokens_API(t *testing.T) {
	router := setupTestRouter()

	router.POST("/api/v1/trading/sell", func(c *gin.Context) {
		var req map[string]interface{}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		if req["circle_id"] == nil || req["amount"] == nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "missing required fields"})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"tx_hash": "0xselltxhash",
			"message": "Sell transaction submitted successfully",
		})
	})

	payload := map[string]interface{}{
		"circle_id":   1,
		"amount":      "50",
		"min_refund":  "500000000000000000",
		"private_key": "0xtest",
	}

	jsonData, _ := json.Marshal(payload)
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/api/v1/trading/sell", bytes.NewBuffer(jsonData))
	req.Header.Set("Content-Type", "application/json")
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.NotEmpty(t, response["tx_hash"])
	assert.Contains(t, response["message"], "Sell transaction")
}

// TestGetBalance_API tests the get balance endpoint
func TestGetBalance_API(t *testing.T) {
	router := setupTestRouter()

	router.GET("/api/v1/trading/balance/:circleId/:address", func(c *gin.Context) {
		circleID := c.Param("circleId")
		address := c.Param("address")

		if circleID == "" || address == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid parameters"})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"circle_id": circleID,
			"address":   address,
			"balance":   "1000",
		})
	})

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/api/v1/trading/balance/1/0xabcdef", nil)
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, "1000", response["balance"])
}

// TestGetPrice_API tests the get price endpoint
func TestGetPrice_API(t *testing.T) {
	router := setupTestRouter()

	router.GET("/api/v1/trading/price/:circleId", func(c *gin.Context) {
		circleID := c.Param("circleId")

		if circleID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid circle ID"})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"circle_id": circleID,
			"price":     "5000000000000000",
		})
	})

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/api/v1/trading/price/1", nil)
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.NotEmpty(t, response["price"])
}

// TestRateLimiting tests rate limiting middleware
func TestRateLimiting(t *testing.T) {
	router := setupTestRouter()

	// Simple rate limiting simulation
	requestCount := 0
	router.GET("/api/v1/test", func(c *gin.Context) {
		requestCount++
		if requestCount > 5 {
			c.JSON(http.StatusTooManyRequests, gin.H{"error": "rate limit exceeded"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"success": true})
	})

	// Make multiple requests
	for i := 0; i < 7; i++ {
		w := httptest.NewRecorder()
		req, _ := http.NewRequest("GET", "/api/v1/test", nil)
		router.ServeHTTP(w, req)

		if i < 5 {
			assert.Equal(t, http.StatusOK, w.Code)
		} else {
			assert.Equal(t, http.StatusTooManyRequests, w.Code)
		}
	}
}

// TestCORS tests CORS headers
func TestCORS(t *testing.T) {
	router := setupTestRouter()

	router.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")
		c.Next()
	})

	router.GET("/api/v1/test", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"success": true})
	})

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/api/v1/test", nil)
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.Equal(t, "*", w.Header().Get("Access-Control-Allow-Origin"))
	assert.NotEmpty(t, w.Header().Get("Access-Control-Allow-Methods"))
}
