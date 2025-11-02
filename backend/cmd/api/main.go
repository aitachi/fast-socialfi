// Author: Aitachi
// Email: 44158892@qq.com
// Date: 11-02-2025 17

package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/fast-socialfi/backend/internal/config"
	"github.com/fast-socialfi/backend/internal/database"
	"github.com/fast-socialfi/backend/internal/handlers"
	"github.com/fast-socialfi/backend/internal/middleware"
	"github.com/fast-socialfi/backend/internal/services"
	"github.com/fast-socialfi/backend/pkg/logger"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables
	if err := godotenv.Load("../../.env"); err != nil {
		log.Printf("Warning: .env file not found: %v", err)
	}

	// Initialize logger
	logger.Init()
	logger.Info("Starting SocialFi Backend API Server...")

	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		logger.Fatal("Failed to load configuration", "error", err)
	}

	// Initialize database
	db, err := database.NewConnection(cfg.Database)
	if err != nil {
		logger.Fatal("Failed to connect to database", "error", err)
	}
	defer database.Close()

	// Initialize Redis (if enabled)
	var redisClient *database.RedisClient
	if cfg.Redis.Enabled {
		redisClient, err = database.NewRedisClient(cfg.Redis)
		if err != nil {
			logger.Error("Failed to connect to Redis", "error", err)
		} else {
			defer redisClient.Close()
		}
	}

	// Initialize services
	userService := services.NewUserService(db)
	circleService := services.NewCircleService(db)
	postService := services.NewPostService(db)
	tradeService := services.NewTradeService(db)
	web3Service, err := services.NewWeb3Service(cfg.Blockchain)
	if err != nil {
		logger.Fatal("Failed to initialize Web3 service", "error", err)
	}

	// Setup Gin router
	if cfg.App.Environment == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.New()
	router.Use(gin.Recovery())
	router.Use(middleware.Logger())
	router.Use(middleware.CORS())
	router.Use(middleware.RateLimiter(cfg.Security.RateLimit))

	// Health check endpoint
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "healthy",
			"time":   time.Now().Unix(),
		})
	})

	// API v1 routes
	v1 := router.Group("/api/v1")
	{
		// User routes
		users := v1.Group("/users")
		{
			userHandler := handlers.NewUserHandler(userService, web3Service)
			users.POST("/register", userHandler.Register)
			users.GET("/:address", userHandler.GetUser)
			users.PUT("/profile", middleware.Auth(), userHandler.UpdateProfile)
			users.GET("/:address/circles", userHandler.GetUserCircles)
			users.POST("/follow", middleware.Auth(), userHandler.FollowUser)
			users.POST("/unfollow", middleware.Auth(), userHandler.UnfollowUser)
			users.GET("/:address/followers", userHandler.GetFollowers)
			users.GET("/:address/following", userHandler.GetFollowing)
		}

		// Circle routes
		circles := v1.Group("/circles")
		{
			circleHandler := handlers.NewCircleHandler(circleService, web3Service)
			circles.POST("", middleware.Auth(), circleHandler.CreateCircle)
			circles.GET("/:id", circleHandler.GetCircle)
			circles.GET("/trending", circleHandler.GetTrending)
			circles.GET("", circleHandler.ListCircles)
			circles.PUT("/:id", middleware.Auth(), circleHandler.UpdateCircle)
			circles.POST("/:id/join", middleware.Auth(), circleHandler.JoinCircle)
			circles.GET("/:id/members", circleHandler.GetMembers)
			circles.GET("/:id/stats", circleHandler.GetStats)
		}

		// Post routes
		posts := v1.Group("/posts")
		{
			postHandler := handlers.NewPostHandler(postService, web3Service)
			posts.POST("", middleware.Auth(), postHandler.CreatePost)
			posts.GET("/:id", postHandler.GetPost)
			posts.GET("", postHandler.ListPosts)
			posts.PUT("/:id", middleware.Auth(), postHandler.UpdatePost)
			posts.DELETE("/:id", middleware.Auth(), postHandler.DeletePost)
			posts.POST("/:id/upvote", middleware.Auth(), postHandler.Upvote)
			posts.POST("/:id/downvote", middleware.Auth(), postHandler.Downvote)
			posts.POST("/:id/comment", middleware.Auth(), postHandler.AddComment)
			posts.GET("/:id/comments", postHandler.GetComments)
			posts.POST("/:id/reward", middleware.Auth(), postHandler.RewardPost)
		}

		// Trade routes
		trades := v1.Group("/trades")
		{
			tradeHandler := handlers.NewTradeHandler(tradeService, web3Service)
			trades.POST("/buy", middleware.Auth(), tradeHandler.BuyTokens)
			trades.POST("/sell", middleware.Auth(), tradeHandler.SellTokens)
			trades.GET("/history", middleware.Auth(), tradeHandler.GetTradeHistory)
			trades.GET("/price/:circleId", tradeHandler.GetPrice)
			trades.GET("/price-impact/:circleId", tradeHandler.GetPriceImpact)
		}

		// Analytics routes
		analytics := v1.Group("/analytics")
		{
			analyticsHandler := handlers.NewAnalyticsHandler(db)
			analytics.GET("/dashboard", analyticsHandler.GetDashboard)
			analytics.GET("/user/:address", analyticsHandler.GetUserAnalytics)
			analytics.GET("/circle/:id", analyticsHandler.GetCircleAnalytics)
		}

		// Notification routes
		notifications := v1.Group("/notifications")
		{
			notificationHandler := handlers.NewNotificationHandler(db)
			notifications.GET("", middleware.Auth(), notificationHandler.GetNotifications)
			notifications.PUT("/:id/read", middleware.Auth(), notificationHandler.MarkAsRead)
			notifications.DELETE("/:id", middleware.Auth(), notificationHandler.DeleteNotification)
		}
	}

	// WebSocket endpoint for real-time updates
	router.GET("/ws", func(c *gin.Context) {
		// WebSocket handler implementation
		handlers.HandleWebSocket(c.Writer, c.Request, web3Service)
	})

	// Start server
	srv := &http.Server{
		Addr:           fmt.Sprintf("%s:%s", cfg.App.Host, cfg.App.Port),
		Handler:        router,
		ReadTimeout:    30 * time.Second,
		WriteTimeout:   30 * time.Second,
		MaxHeaderBytes: 1 << 20,
	}

	// Start server in goroutine
	go func() {
		logger.Info("Server starting", "address", srv.Addr)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("Failed to start server", "error", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("Shutting down server...")

	// Graceful shutdown with 5 second timeout
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		logger.Fatal("Server forced to shutdown", "error", err)
	}

	logger.Info("Server exited")
}
