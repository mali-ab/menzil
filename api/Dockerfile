FROM golang:1.25-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/menzil-api ./cmd/api

FROM alpine:3.22
RUN apk add --no-cache ca-certificates tzdata
WORKDIR /app
COPY --from=build /out/menzil-api /usr/local/bin/menzil-api
RUN addgroup -S menzil && adduser -S -G menzil menzil && mkdir -p /app/uploads && chown -R menzil:menzil /app
USER menzil
EXPOSE 8080
ENTRYPOINT ["menzil-api"]
