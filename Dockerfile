FROM rust:1.64.0 as builder

WORKDIR /app
COPY . .
RUN cargo install --path .
RUN cargo build

FROM debian:buster-slim
ENV ROCKET_ADDRESS=0.0.0.0
ENV ROCKET_PORT=3000
COPY --from=builder /app /app
CMD ["./app/target/debug/hello_rocket"]