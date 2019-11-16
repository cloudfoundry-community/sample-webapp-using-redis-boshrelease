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
	redisCounterKey := os.Getenv("REDIS_COUNTER_KEY")
	if redisCounterKey == "" {
		redisCounterKey = "counter"
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

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		val, err := client.Get(redisCounterKey).Int()
		if err == redis.Nil {
			// defaults to 0
		} else if err != nil {
			fmt.Fprintf(w, "Cannot connect to Redis backend\n")
		}
		val++
		client.Set(redisCounterKey, strconv.Itoa(val), 0)
		fmt.Fprintf(w, "%s=%d\n", redisCounterKey, val)
	})

	fmt.Printf("Web app listening on :%s...\n", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
