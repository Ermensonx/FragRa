FROM golang:1.21-alpine AS builder

WORKDIR /app

COPY main.go .
RUN go build -o secrets-vault main.go

FROM alpine:latest

WORKDIR /app

RUN adduser -D -u 1000 vaultuser

COPY --from=builder /app/secrets-vault .

USER vaultuser

EXPOSE 443

CMD ["./secrets-vault"]
