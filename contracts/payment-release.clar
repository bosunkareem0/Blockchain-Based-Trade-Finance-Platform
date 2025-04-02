;; Payment Release Contract
;; Automates funds transfer when conditions are met

(define-data-var admin principal tx-sender)

;; Status enum for payments
(define-constant STATUS-PENDING u1)
(define-constant STATUS-RELEASED u2)
(define-constant STATUS-REFUNDED u3)
(define-constant STATUS-DISPUTED u4)

;; Data structure for payments
(define-map payments
  { payment-id: (string-ascii 64) }
  {
    lc-id: (string-ascii 64),
    payer: principal,
    payee: principal,
    amount: uint,
    status: uint,
    escrow-height: uint,
    release-height: uint
  }
)

;; Public function to create a payment in escrow
(define-public (create-payment
                (payment-id (string-ascii 64))
                (lc-id (string-ascii 64))
                (payee principal)
                (amount uint)
                (release-blocks uint))
  (let ((caller tx-sender)
        (release-height (+ block-height release-blocks)))
    (if (and (> amount u0)
             (map-insert payments
                         { payment-id: payment-id }
                         {
                           lc-id: lc-id,
                           payer: caller,
                           payee: payee,
                           amount: amount,
                           status: STATUS-PENDING,
                           escrow-height: block-height,
                           release-height: release-height
                         }))
        ;; In a real implementation, this would transfer STX to escrow
        (ok true)
        (err u1))))

;; Admin function to release payment
(define-public (release-payment (payment-id (string-ascii 64)))
  (let ((caller tx-sender))
    (if (is-eq caller (var-get admin))
        (match (map-get? payments { payment-id: payment-id })
          payment-data (if (is-eq (get status payment-data) STATUS-PENDING)
                           (begin
                             (map-set payments
                                      { payment-id: payment-id }
                                      (merge payment-data { status: STATUS-RELEASED }))
                             ;; In a real implementation, this would transfer STX from escrow to payee
                             (ok true))
                           (err u2))
          (err u3))
        (err u4))))

;; Admin function to refund payment
(define-public (refund-payment (payment-id (string-ascii 64)))
  (let ((caller tx-sender))
    (if (is-eq caller (var-get admin))
        (match (map-get? payments { payment-id: payment-id })
          payment-data (if (is-eq (get status payment-data) STATUS-PENDING)
                           (begin
                             (map-set payments
                                      { payment-id: payment-id }
                                      (merge payment-data { status: STATUS-REFUNDED }))
                             ;; In a real implementation, this would transfer STX from escrow back to payer
                             (ok true))
                           (err u5))
          (err u6))
        (err u7))))

;; Function to dispute a payment
(define-public (dispute-payment (payment-id (string-ascii 64)))
  (let ((caller tx-sender))
    (match (map-get? payments { payment-id: payment-id })
      payment-data (if (and (is-eq (get status payment-data) STATUS-PENDING)
                            (or (is-eq caller (get payer payment-data))
                                (is-eq caller (get payee payment-data))))
                       (begin
                         (map-set payments
                                  { payment-id: payment-id }
                                  (merge payment-data { status: STATUS-DISPUTED }))
                         (ok true))
                       (err u8))
      (err u9))))

;; Read-only function to get payment details
(define-read-only (get-payment-details (payment-id (string-ascii 64)))
  (map-get? payments { payment-id: payment-id }))

;; Read-only function to check if payment can be automatically released
(define-read-only (can-auto-release (payment-id (string-ascii 64)))
  (match (map-get? payments { payment-id: payment-id })
    payment-data (and (is-eq (get status payment-data) STATUS-PENDING)
                      (>= block-height (get release-height payment-data)))
    false))

;; Function to automatically release payment after release height
(define-public (auto-release-payment (payment-id (string-ascii 64)))
  (if (can-auto-release payment-id)
      (match (map-get? payments { payment-id: payment-id })
        payment-data (begin
          (map-set payments
                   { payment-id: payment-id }
                   (merge payment-data { status: STATUS-RELEASED }))
          ;; In a real implementation, this would transfer STX from escrow to payee
          (ok true))
        (err u10))
      (err u11)))
