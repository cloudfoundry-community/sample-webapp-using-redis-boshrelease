package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"

	"github.com/go-redis/redis/v7"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	redisHost := os.Getenv("REDIS_HOST")
	if redisHost == "" {
		redisHost = "localhost"
	}
	redisPort := os.Getenv("REDIS_PORT")
	if redisPort == "" {
		redisPort = "6379"
	}
	redisDBNum := os.Getenv("REDIS_DBNUM")
	if redisDBNum == "" {
		redisDBNum = "0"
	}
	redisDB, _ := strconv.ParseInt(redisDBNum, 10, 32)
	redisPassword := os.Getenv("REDIS_PASSWORD")
	redisAddr := fmt.Sprintf("%s:%s", redisHost, redisPort)
	fmt.Printf("Connecting redis server %s...\n", redisAddr)
	client := redis.NewClient(&redis.Options{
		Addr:     redisAddr,
		Password: redisPassword,
		DB:       int(redisDB), // use default DB
	})
	pong, err := client.Ping().Result()
	fmt.Println(pong, err)

	log.Fatal(http.ListenAndServe(":"+port, nil))
}
