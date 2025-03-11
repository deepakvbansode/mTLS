package main

import (
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
)

const (
	serverPort = ":8080" // Port for this server
	apiURL     = "https://localhost:90/private/v1/upcoming-movies" // mTLS API endpoint
)

// Health endpoint handler
func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, `{"status": "healthy"}`)
}

// Test endpoint handler
func testHandler(w http.ResponseWriter, r *http.Request) {
	// Load client certificate and key
	clientCert, err := tls.LoadX509KeyPair("./certs/client_crt.pem", "./certs/client_key.pem")
	if err != nil {
		http.Error(w, "Failed to load client certificate", http.StatusInternalServerError)
		log.Printf("Failed to load client certificate: %v", err)
		return
	}

	// Load CA certificate
	caCert, err := ioutil.ReadFile("./certs/ca_crt.pem")
	if err != nil {
		http.Error(w, "Failed to read CA certificate", http.StatusInternalServerError)
		log.Printf("Failed to read CA certificate: %v", err)
		return
	}

	// Create a CA certificate pool
	caCertPool := x509.NewCertPool()
	caCertPool.AppendCertsFromPEM(caCert)

	// Create a TLS configuration with mTLS
	tlsConfig := &tls.Config{
		Certificates: []tls.Certificate{clientCert},
		RootCAs:      caCertPool,
	}

	// Create an HTTP client with the TLS configuration
	client := &http.Client{
		Transport: &http.Transport{
			TLSClientConfig: tlsConfig,
		},
	}

	// Make a request to the API
	resp, err := client.Get(apiURL)
	if err != nil {
		http.Error(w, "Failed to make request to API", http.StatusInternalServerError)
		log.Printf("Failed to make request to API: %v", err)
		return
	}
	defer resp.Body.Close()

	// Read the response body
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		http.Error(w, "Failed to read API response", http.StatusInternalServerError)
		log.Printf("Failed to read API response: %v", err)
		return
	}

	// Return the API response
	w.WriteHeader(resp.StatusCode)
	w.Write(body)
}

func main() {
	// Load server certificate and key
	serverCert, err := tls.LoadX509KeyPair("./certs/client_crt.pem", "./certs/client_key.pem")
	if err != nil {
		log.Fatalf("Failed to load server certificate: %v", err)
	}

	// Load CA certificate
	caCert, err := ioutil.ReadFile("./certs/ca_crt.pem")
	if err != nil {
		log.Fatalf("Failed to read CA certificate: %v", err)
	}

	// Create a CA certificate pool
	caCertPool := x509.NewCertPool()
	caCertPool.AppendCertsFromPEM(caCert)

	// Create a TLS configuration with mTLS
	tlsConfig := &tls.Config{
		Certificates: []tls.Certificate{serverCert}, // Server certificate
		ClientCAs:    caCertPool,                   // CA to verify client certificates
		ClientAuth:   tls.RequireAndVerifyClientCert, // Require client certificates
	}

	// Create an HTTP server with the TLS configuration
	server := &http.Server{
		Addr:      serverPort,
		TLSConfig: tlsConfig,
	}

	// Define routes
	http.HandleFunc("/v1/health", healthHandler)
	http.HandleFunc("/v1/test", testHandler)

	// Start the server with TLS
	log.Printf("Server is running on https://localhost%s", serverPort)
	if err := server.ListenAndServeTLS("", ""); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}