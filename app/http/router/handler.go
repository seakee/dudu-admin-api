// Copyright 2024 Seakee.  All rights reserved.
// Use of this source code is governed by a MIT style
// license that can be found in the LICENSE file.

// Package router handles the routing for the application.
package router

import (
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/seakee/dudu-admin-api/app/http"
	"github.com/seakee/dudu-admin-api/app/http/router/external"
	"github.com/seakee/dudu-admin-api/app/http/router/internal"
)

func Register(engine *gin.Engine, ctx *http.Context) {
	ctx.Engine = engine

	routePrefix := "dudu-admin-api"
	if ctx != nil && ctx.Config != nil {
		routePrefix = strings.Trim(ctx.Config.System.RoutePrefix, "/")
	}

	api := engine.Group(routePrefix)

	// Set up internal API routes
	internalAPI := api.Group("internal")
	internal.RegisterRoutes(internalAPI, ctx)

	// Set up external API routes
	externalAPI := api.Group("external")
	external.RegisterRoutes(externalAPI, ctx)
}
