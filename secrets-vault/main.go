package main

import (
	"crypto/tls"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"strings"
)

var (
	rootFlag      string
	expectedToken string
)

func init() {
	rootFlag = os.Getenv("ROOT_FLAG")
	if rootFlag == "" {
		rootFlag = "HTB{default_root_flag_not_set}"
	}

	// Read expected token from file
	tokenFile := os.Getenv("VALID_TOKEN_FILE")
	if tokenFile == "" {
		tokenFile = "/app/expected-token"
	}
	data, err := os.ReadFile(tokenFile)
	if err != nil {
		log.Printf("Warning: Could not read token file: %v", err)
		expectedToken = "test-token-12345"
	} else {
		expectedToken = strings.TrimSpace(string(data))
	}
}

type Response struct {
	Status  string      `json:"status,omitempty"`
	Error   string      `json:"error,omitempty"`
	Data    interface{} `json:"data,omitempty"`
	Flag    string      `json:"flag,omitempty"`
	Message string      `json:"message,omitempty"`
}

func jsonResponse(w http.ResponseWriter, status int, resp Response) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(resp)
}

func validateToken(r *http.Request) bool {
	auth := r.Header.Get("Authorization")
	if auth == "" {
		return false
	}

	// Expect "Bearer <token>"
	parts := strings.Split(auth, " ")
	if len(parts) != 2 || parts[0] != "Bearer" {
		return false
	}

	return parts[1] == expectedToken
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	jsonResponse(w, http.StatusOK, Response{
		Status: "ok",
		Data:   map[string]string{"service": "secrets-vault", "version": "0.9.3"},
	})
}

func rootHandler(w http.ResponseWriter, r *http.Request) {
	jsonResponse(w, http.StatusOK, Response{
		Status: "ok",
		Data: map[string]interface{}{
			"service":   "secrets-vault",
			"version":   "0.9.3",
			"endpoints": []string{"/health", "/api/v1/secrets/", "/api/v1/auth/verify"},
			"auth":      "Required: Authorization: Bearer <service-account-token>",
		},
	})
}

func authVerifyHandler(w http.ResponseWriter, r *http.Request) {
	if !validateToken(r) {
		jsonResponse(w, http.StatusUnauthorized, Response{
			Error:   "Invalid or missing token",
			Message: "Provide valid service account token in Authorization header",
		})
		return
	}

	jsonResponse(w, http.StatusOK, Response{
		Status:  "authenticated",
		Message: "Token is valid. You may access /api/v1/secrets/*",
	})
}

func secretsHandler(w http.ResponseWriter, r *http.Request) {
	if !validateToken(r) {
		jsonResponse(w, http.StatusUnauthorized, Response{
			Error:   "Authentication required",
			Message: "Provide valid service account token in Authorization: Bearer header",
		})
		return
	}

	// Extract secret name from path
	path := strings.TrimPrefix(r.URL.Path, "/api/v1/secrets/")
	
	secrets := map[string]interface{}{
		"root-flag": map[string]string{
			"flag":    rootFlag,
			"message": "Congratulations! You achieved full compromise of the Cloud Fragment.",
		},
		"db-password": map[string]string{
			"value": "pr0d_db_p4ssw0rd_2024!",
			"note":  "Not the flag you're looking for",
		},
		"api-key": map[string]string{
			"value": "sk_live_xyzABC123def456",
			"note":  "Not the flag you're looking for",
		},
	}

	if path == "" {
		// List available secrets
		keys := make([]string, 0, len(secrets))
		for k := range secrets {
			keys = append(keys, k)
		}
		jsonResponse(w, http.StatusOK, Response{
			Status: "ok",
			Data:   map[string]interface{}{"available_secrets": keys},
		})
		return
	}

	if secret, ok := secrets[path]; ok {
		jsonResponse(w, http.StatusOK, Response{
			Status: "ok",
			Data:   secret,
		})
	} else {
		jsonResponse(w, http.StatusNotFound, Response{
			Error: "Secret not found",
		})
	}
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/", rootHandler)
	mux.HandleFunc("/health", healthHandler)
	mux.HandleFunc("/api/v1/auth/verify", authVerifyHandler)
	mux.HandleFunc("/api/v1/secrets/", secretsHandler)

	// Generate self-signed TLS config
	cert, err := tls.X509KeyPair([]byte(selfSignedCert), []byte(selfSignedKey))
	if err != nil {
		log.Fatalf("Failed to load TLS cert: %v", err)
	}

	server := &http.Server{
		Addr:    ":443",
		Handler: mux,
		TLSConfig: &tls.Config{
			Certificates: []tls.Certificate{cert},
		},
	}

	log.Println("Secrets vault starting on :443")
	if err := server.ListenAndServeTLS("", ""); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}

// Self-signed certificate for internal TLS
const selfSignedCert = `-----BEGIN CERTIFICATE-----
MIIFCTCCAvGgAwIBAgIUV+NOdQgabHIEs8bHE3KZExaOQ2kwDQYJKoZIhvcNAQEL
BQAwFDESMBAGA1UEAwwJbG9jYWxob3N0MB4XDTI1MTIzMTA0NTM0OFoXDTI2MTIz
MTA0NTM0OFowFDESMBAGA1UEAwwJbG9jYWxob3N0MIICIjANBgkqhkiG9w0BAQEF
AAOCAg8AMIICCgKCAgEAxgToDC7n7IgnynZ6gXvvmH6ZEzwg14NyDgm6wiACPtPU
SDWq41Jf5b6rbvyUh6QXbXqCA7snEjvEjYABE1xJITwUR3iYwJ6ziZYiBkvF/6cu
84zXd/fdKoIKfef6mc8FyYIcCQPhMl0J7dKCSuYjbr1ylJhJ8Enz0PNtWSLxs7Fj
nflWB1twdca/VMqCLCF+K1pOY5M76PLLEhYvolZrNgqTqA/oZRFlkl8R6w9ra9rk
NNxqI0x9JfEy4MJ4ucP0e/Joy23Jkh07si9inqspnP7e9+jgN0R8Z6ohXORUZRjf
3hyzpjm5L3pegvhlMMs5eantAovN9dsSGlXF9aj7VBfOcrTjIjQajRaRN7fwV3PW
8zouQSvZSDe+ImrOs2+rqICscP+xsL3RnCZvQiLy/vxD03/Wvo5LGOGjojCT9Z1d
qy0ePa6yyMP8f2heXve97YCOWgiDgXCrCvvbT8t4bIZjHxpXlZbbcNEUyPp7ox4J
u0VlaAiW3M93BQXFxFC27NA/q4NCdNUDiA/l6VsnzkoFiegIfPz1E7lDG2GNfmvi
w4UxO9XOFbc+1ZZHBA6qUCPRzlDt3UVQNDE395Xk86xYOkmfD53h/tZBtzTQfK8A
P7Fa9vfN/a5IEUIaRtUha8QzD4u9HHX/8qTcb9CXvtyg3t991rHbrz74HYKMh6MC
AwEAAaNTMFEwHQYDVR0OBBYEFIfAeZyLAb+sPxkkMJIn3Afi27+1MB8GA1UdIwQY
MBaAFIfAeZyLAb+sPxkkMJIn3Afi27+1MA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZI
hvcNAQELBQADggIBAG6F/NOxkVPthjpi/h4jKCDF+DQ7jETLambD11oqUjjYdZdK
DJZGj2kuUFhVw9WWJ0diVV7Rlx0y7Ud0GLKs7+yDjw11vdc+k43t7RiiIqADDVYb
YeSD8G+/BqmaHpv6pb3jXkkSM+fR/GCkusVfYZc8NzeyDfok4m4hPdTLh6devEFR
TGyeuK88eenucFz1HAWIQ/hmBy8GU8MyVtIsNwyTqD56rc+5SSgjA9S+tOHUXiIR
z3B3z0xrxY+eyui11wRFbWx+A8cq76lYwG4UwuodVwhEXslt0kgndQd16Tm/JyYq
Wnuiwnj765+A8Y1VDUJRn/WbcN5z3XeJUE9feAWXWlDGLAeAuWsNWOOlg1oquBoY
vV5QGZ62jU9WVzUbRoMQQhl6AwRWVzhLu+kvHJ8fqS7aq9zg4ALWmPH6pm/9t/YG
vRoCtj8WBhtqV1YsvmpYacUpe1Jy2zL8VvtqtUT4iqi5OmkvUPOisITtHMxc6Jy2
Istv3YXqCjVL+SmwMnwD+rQKzB0vEzOLRghxabi5OXPu1eu7B62G8iU0Tcw8VoM5
e5rT5gfd2qb+JWvHRlqi3urH5jnejrZe980OtNopMKGlY7uJoO0AuSZi18Hq9MVv
vQUX4NtmGrqmzY5T1isgXHN8udWvIpgKdXuff5DkaEmJGghpvRoP8ewWNUg+
-----END CERTIFICATE-----`

const selfSignedKey = `-----BEGIN PRIVATE KEY-----
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
XuNT7s8MPaPbpHI2sWtTjJBuRojjKA==
-----END PRIVATE KEY-----`
