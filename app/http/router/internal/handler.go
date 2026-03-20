package internal

import (
	"github.com/gin-gonic/gin"
	"github.com/seakee/dudu-admin-api/app/http"
	"github.com/seakee/dudu-admin-api/app/http/router/internal/admin"
	"github.com/seakee/dudu-admin-api/app/http/router/internal/service"
)

// RegisterRoutes registers all internal API routes.
func RegisterRoutes(api *gin.RouterGroup, ctx *http.Context) {
	api.GET("ping", func(c *gin.Context) {
		ctx.I18n.JSON(c, 0, nil, nil)
	})

	serviceAPI := api.Group("service")
	service.RegisterRoutes(serviceAPI, ctx)

	// Register Admin related routes
	adminAPI := api.Group("admin")
	admin.RegisterRoutes(adminAPI, ctx)
}
