package system

import (
	"github.com/gin-gonic/gin"
	"github.com/seakee/dudu-admin-api/app/http"
	"github.com/seakee/dudu-admin-api/app/http/controller/admin/system/permission"
)

func registerPermissionRoutes(api *gin.RouterGroup, ctx *http.Context) {
	handler := permission.NewHandler(ctx)

	api.POST("", handler.Create())
	api.DELETE("", handler.Delete())
	api.PUT("", handler.Update())
	api.GET("", handler.Detail())
	api.GET("list", handler.List())
	api.GET("paginate", handler.Paginate())
	api.GET("available", handler.Available())
}
