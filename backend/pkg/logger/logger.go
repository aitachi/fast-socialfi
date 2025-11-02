// Author: Aitachi
// Email: 44158892@qq.com
// Date: 11-02-2025 17

package logger

import (
	"os"

	"github.com/sirupsen/logrus"
)

var log *logrus.Logger

func Init() {
	log = logrus.New()
	log.SetFormatter(&logrus.JSONFormatter{
		TimestampFormat: "2006-01-02 15:04:05",
	})
	log.SetOutput(os.Stdout)

	// Set log level based on environment
	env := os.Getenv("LOG_LEVEL")
	switch env {
	case "debug":
		log.SetLevel(logrus.DebugLevel)
	case "info":
		log.SetLevel(logrus.InfoLevel)
	case "warn":
		log.SetLevel(logrus.WarnLevel)
	case "error":
		log.SetLevel(logrus.ErrorLevel)
	default:
		log.SetLevel(logrus.InfoLevel)
	}
}

func Debug(msg string, fields ...interface{}) {
	if log == nil {
		Init()
	}
	log.WithFields(parseFields(fields...)).Debug(msg)
}

func Info(msg string, fields ...interface{}) {
	if log == nil {
		Init()
	}
	log.WithFields(parseFields(fields...)).Info(msg)
}

func Warn(msg string, fields ...interface{}) {
	if log == nil {
		Init()
	}
	log.WithFields(parseFields(fields...)).Warn(msg)
}

func Error(msg string, fields ...interface{}) {
	if log == nil {
		Init()
	}
	log.WithFields(parseFields(fields...)).Error(msg)
}

func Fatal(msg string, fields ...interface{}) {
	if log == nil {
		Init()
	}
	log.WithFields(parseFields(fields...)).Fatal(msg)
}

func parseFields(fields ...interface{}) logrus.Fields {
	f := logrus.Fields{}
	for i := 0; i < len(fields)-1; i += 2 {
		key, ok := fields[i].(string)
		if !ok {
			continue
		}
		f[key] = fields[i+1]
	}
	return f
}

func GetLogger() *logrus.Logger {
	if log == nil {
		Init()
	}
	return log
}
