;; Exporter Verification Contract
;; This contract validates seller credentials and history

(define-data-var admin principal tx-sender)

;; Data structure for exporters
(define-map exporters
  { exporter-id: (string-ascii 64) }
  {
    principal: principal,
    name: (string-ascii 256),
    country: (string-ascii 64),
    verified: bool,
    rating: uint,
    total-transactions: uint
  }
)

;; Public function to register a new exporter
(define-public (register-exporter (exporter-id (string-ascii 64)) (name (string-ascii 256)) (country (string-ascii 64)))
  (let ((caller tx-sender))
    (if (map-insert exporters
                    { exporter-id: exporter-id }
                    {
                      principal: caller,
                      name: name,
                      country: country,
                      verified: false,
                      rating: u0,
                      total-transactions: u0
                    })
        (ok true)
        (err u1))))

;; Admin function to verify an exporter
(define-public (verify-exporter (exporter-id (string-ascii 64)))
  (let ((caller tx-sender))
    (if (is-eq caller (var-get admin))
        (match (map-get? exporters { exporter-id: exporter-id })
          exporter-data (begin
            (map-set exporters
                     { exporter-id: exporter-id }
                     (merge exporter-data { verified: true }))
            (ok true))
          (err u2))
        (err u3))))

;; Update exporter rating after successful transaction
(define-public (update-exporter-rating (exporter-id (string-ascii 64)) (new-rating uint))
  (let ((caller tx-sender))
    (if (is-eq caller (var-get admin))
        (match (map-get? exporters { exporter-id: exporter-id })
          exporter-data (begin
            (map-set exporters
                     { exporter-id: exporter-id }
                     (merge exporter-data {
                       rating: new-rating,
                       total-transactions: (+ (get total-transactions exporter-data) u1)
                     }))
            (ok true))
          (err u4))
        (err u5))))

;; Read-only function to check if an exporter is verified
(define-read-only (is-verified (exporter-id (string-ascii 64)))
  (match (map-get? exporters { exporter-id: exporter-id })
    exporter-data (get verified exporter-data)
    false))

;; Read-only function to get exporter details
(define-read-only (get-exporter-details (exporter-id (string-ascii 64)))
  (map-get? exporters { exporter-id: exporter-id }))

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (let ((caller tx-sender))
    (if (is-eq caller (var-get admin))
        (begin
          (var-set admin new-admin)
          (ok true))
        (err u6))))
