// Copyright 2024 Seakee.  All rights reserved.
// Use of this source code is governed by a MIT style
// license that can be found in the LICENSE file.

// Package config provides configuration management for the application.
// It includes structures for various configuration aspects such as system settings,
// logging, databases, caching, and external service integrations.
package config

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
)

const (
	envKey        = "RUN_ENV"         // Environment variable key for the running environment
	nameKey       = "APP_NAME"        // Environment variable key for the application name
	configPathKey = "APP_CONFIG_PATH" // Environment variable key for the explicit config path
)

var (
	config *Config // Global configuration variable

	placeholderConfigValues = map[string]struct{}{
		"db_host":                 {},
		"db_username":             {},
		"db_password":             {},
		"mongodb://db_host:27017": {},
		"host:6379":               {},
	}
)

// Config represents the entire application configuration.
type Config struct {
	System    SysConfig  `json:"system"`    // System-wide configuration
	Log       LogConfig  `json:"log"`       // Logging configuration
	Databases []Database `json:"databases"` // Database configurations
	Cache     Cache      `json:"cache"`     // Caching configuration
	Redis     []Redis    `json:"redis"`     // Redis configurations
	Kafka     Kafka      `json:"kafka"`     // Kafka configuration
	Monitor   Monitor    `json:"monitor"`   // Monitoring configuration
	Notify    Notify     `json:"notify"`    // Notify configuration
}

// LoadConfig loads the application configuration from a JSON file.
// It determines the configuration file to load based on the runtime environment,
// unmarshal the JSON content into a Config struct, and performs some post-processing.
//
// The function uses environment variables to determine the runtime environment and application name.
// If these are not set, it falls back to default values.
//
// Returns:
//   - *Config: A pointer to the loaded configuration structure.
//   - error: An error if any occurred during the loading process.
func LoadConfig() (*Config, error) {
	var (
		runEnv         string
		appName        string
		configFilePath string
		rootPath       string
		cfgContent     []byte
		err            error
	)

	// Get the runtime environment from environment variable, default to "local"
	runEnv = os.Getenv(envKey)
	if runEnv == "" {
		runEnv = "local"
	}

	// Get the current working directory
	rootPath, err = os.Getwd()
	if err != nil {
		log.Fatalf("Unable to get working directory: %v", err)
	}

	configFilePath = os.Getenv(configPathKey)
	if configFilePath == "" {
		configFilePath = filepath.Join(rootPath, "bin", "configs", fmt.Sprintf("%s.json", runEnv))
	}

	cfgContent, err = os.ReadFile(configFilePath)
	if err != nil {
		return nil, err
	}

	// Unmarshal JSON content into the config struct
	err = json.Unmarshal(cfgContent, &config)
	if err != nil {
		return nil, err
	}

	// Override application name if set in environment variable
	appName = os.Getenv(nameKey)
	if appName != "" {
		config.System.Name = appName
	}

	// Set additional system configuration fields
	config.System.Env = runEnv
	config.System.RootPath = rootPath
	config.System.EnvKey = envKey
	config.System.LangDir = filepath.Join(rootPath, "bin", "lang")
	if config.System.RoutePrefix == "" {
		config.System.RoutePrefix = "dudu-admin-api"
	}

	// Perform configuration checks
	err = checkConfig(config)
	if err != nil {
		return nil, err
	}

	return config, nil
}

// checkConfig performs validation checks on the loaded configuration.
func checkConfig(conf *Config) error {
	if conf.System.JwtSecret == "" {
		return fmt.Errorf("jwtSecret cannot be null")
	}

	if conf.System.ReadTimeout <= 0 {
		return fmt.Errorf("readTimeout cannot be less than or equal to zero")
	}

	if conf.System.WriteTimeout <= 0 {
		return fmt.Errorf("writeTimeout cannot be less than or equal to zero")
	}

	if conf.System.HTTPPort == "" {
		return fmt.Errorf("httpPort cannot be null")
	}

	if conf.System.TokenExpire <= 0 {
		return fmt.Errorf("TokenExpire cannot be less than or equal to zero")
	}

	if err := checkDatabases(conf.Databases); err != nil {
		return err
	}

	if err := checkRedisConfigs(conf.Redis); err != nil {
		return err
	}

	return nil
}

func checkDatabases(databases []Database) error {
	for i, db := range databases {
		if !db.Enable {
			continue
		}

		prefix := fmt.Sprintf("databases[%d]", i)
		if strings.TrimSpace(db.DbType) == "" {
			return fmt.Errorf("%s.db_type cannot be null", prefix)
		}
		if strings.TrimSpace(db.DbName) == "" {
			return fmt.Errorf("%s.db_name cannot be null", prefix)
		}
		if err := requireConfigValue(prefix+".db_host", db.DbHost); err != nil {
			return err
		}

		switch db.DbType {
		case "mysql", "postgres", "sqlserver":
			if err := requireConfigValue(prefix+".db_username", db.DbUsername); err != nil {
				return err
			}
			if err := requireConfigValue(prefix+".db_password", db.DbPassword); err != nil {
				return err
			}
		default:
			if err := rejectPlaceholderConfigValue(prefix+".db_username", db.DbUsername); err != nil {
				return err
			}
			if err := rejectPlaceholderConfigValue(prefix+".db_password", db.DbPassword); err != nil {
				return err
			}
		}
	}

	return nil
}

func checkRedisConfigs(redisConfigs []Redis) error {
	for i, item := range redisConfigs {
		if !item.Enable {
			continue
		}

		prefix := fmt.Sprintf("redis[%d]", i)
		if strings.TrimSpace(item.Name) == "" {
			return fmt.Errorf("%s.name cannot be null", prefix)
		}
		if err := requireConfigValue(prefix+".host", item.Host); err != nil {
			return err
		}
	}

	return nil
}

func requireConfigValue(fieldName, value string) error {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return fmt.Errorf("%s cannot be null", fieldName)
	}

	return rejectPlaceholderConfigValue(fieldName, trimmed)
}

func rejectPlaceholderConfigValue(fieldName, value string) error {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return nil
	}
	if _, ok := placeholderConfigValues[trimmed]; ok {
		return fmt.Errorf("%s contains template placeholder value %q", fieldName, trimmed)
	}
	return nil
}

// Get returns the global configuration object.
// This function should be called after LoadConfig has been executed.
//
// Returns:
//   - *Config: A pointer to the global configuration structure.
//
// Example usage:
//
//	cfg := Get()
//	fmt.Printf("Application name: %s\n", cfg.System.Name)
func Get() *Config {
	return config
}
