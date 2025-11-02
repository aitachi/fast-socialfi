// Author: Aitachi
// Email: 44158892@qq.com
// Date: 11-02-2025 17

package handler

import (
	"net/http"
	"strconv"

	"github.com/fast-socialfi/backend/internal/service"
	"github.com/gin-gonic/gin"
)

// CircleHandler handles circle-related HTTP requests
type CircleHandler struct {
	circleSvc *service.CircleService
}

// NewCircleHandler creates a new circle handler
func NewCircleHandler(circleSvc *service.CircleService) *CircleHandler {
	return &CircleHandler{
		circleSvc: circleSvc,
	}
}

// RegisterRoutes registers circle routes
func (h *CircleHandler) RegisterRoutes(r *gin.RouterGroup) {
	circles := r.Group("/circles")
	{
		circles.POST("", h.CreateCircle)
		circles.GET("", h.ListCircles)
		circles.GET("/:id", h.GetCircle)
		circles.GET("/search", h.SearchCircles)
		circles.GET("/trending", h.GetTrendingCircles)
		circles.PUT("/:id/sync", h.SyncCircleFromBlockchain)
	}
}

// CreateCircle godoc
// @Summary Create a new circle
// @Description Creates a new circle with bonding curve
// @Tags circles
// @Accept json
// @Produce json
// @Param request body service.CreateCircleRequest true "Circle creation request"
// @Success 201 {object} service.CreateCircleResponse
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /api/v1/circles [post]
func (h *CircleHandler) CreateCircle(c *gin.Context) {
	var req service.CreateCircleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "Invalid request",
			Message: err.Error(),
		})
		return
	}

	resp, err := h.circleSvc.CreateCircle(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "Failed to create circle",
			Message: err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, resp)
}

// GetCircle godoc
// @Summary Get circle details
// @Description Retrieves detailed information about a circle
// @Tags circles
// @Produce json
// @Param id path int true "Circle ID"
// @Success 200 {object} models.CircleDetail
// @Failure 400 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Router /api/v1/circles/{id} [get]
func (h *CircleHandler) GetCircle(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "Invalid circle ID",
			Message: err.Error(),
		})
		return
	}

	circle, err := h.circleSvc.GetCircle(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, ErrorResponse{
			Error:   "Circle not found",
			Message: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, circle)
}

// ListCircles godoc
// @Summary List circles
// @Description Retrieves a paginated list of circles
// @Tags circles
// @Produce json
// @Param limit query int false "Limit" default(20)
// @Param offset query int false "Offset" default(0)
// @Success 200 {object} ListCirclesResponse
// @Failure 500 {object} ErrorResponse
// @Router /api/v1/circles [get]
func (h *CircleHandler) ListCircles(c *gin.Context) {
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	if limit > 100 {
		limit = 100
	}

	circles, total, err := h.circleSvc.ListCircles(c.Request.Context(), limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "Failed to list circles",
			Message: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, ListCirclesResponse{
		Circles: circles,
		Total:   total,
		Limit:   limit,
		Offset:  offset,
	})
}

// SearchCircles godoc
// @Summary Search circles
// @Description Searches for circles by name or symbol
// @Tags circles
// @Produce json
// @Param q query string true "Search query"
// @Param limit query int false "Limit" default(20)
// @Param offset query int false "Offset" default(0)
// @Success 200 {array} models.Circle
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /api/v1/circles/search [get]
func (h *CircleHandler) SearchCircles(c *gin.Context) {
	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "Invalid request",
			Message: "Search query is required",
		})
		return
	}

	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	circles, err := h.circleSvc.SearchCircles(c.Request.Context(), query, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "Search failed",
			Message: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, circles)
}

// GetTrendingCircles godoc
// @Summary Get trending circles
// @Description Retrieves trending circles based on activity
// @Tags circles
// @Produce json
// @Param limit query int false "Limit" default(10)
// @Success 200 {array} models.Circle
// @Failure 500 {object} ErrorResponse
// @Router /api/v1/circles/trending [get]
func (h *CircleHandler) GetTrendingCircles(c *gin.Context) {
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	if limit > 50 {
		limit = 50
	}

	circles, err := h.circleSvc.GetTrendingCircles(c.Request.Context(), limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "Failed to get trending circles",
			Message: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, circles)
}

// SyncCircleFromBlockchain godoc
// @Summary Sync circle from blockchain
// @Description Syncs circle data from blockchain
// @Tags circles
// @Produce json
// @Param id path int true "Circle ID"
// @Success 200 {object} SuccessResponse
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /api/v1/circles/{id}/sync [put]
func (h *CircleHandler) SyncCircleFromBlockchain(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "Invalid circle ID",
			Message: err.Error(),
		})
		return
	}

	err = h.circleSvc.UpdateCircleFromBlockchain(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "Failed to sync circle",
			Message: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, SuccessResponse{
		Message: "Circle synced successfully",
	})
}

// Response types
type ErrorResponse struct {
	Error   string `json:"error"`
	Message string `json:"message"`
}

type SuccessResponse struct {
	Message string `json:"message"`
}

type ListCirclesResponse struct {
	Circles interface{} `json:"circles"`
	Total   int64       `json:"total"`
	Limit   int         `json:"limit"`
	Offset  int         `json:"offset"`
}
