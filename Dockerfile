FROM rust:1.64.0 as builder

WORKDIR /app
COPY . .
RUN cargo build --release

FROM debian:buster-slim
ENV ROCKET_ADDRESS=0.0.0.0
ENV ROCKET_PORT=8000
# Replace if you are making a real service
ENV ROCKET_SECRET_KEY="shhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh"
COPY --from=builder /app /app
CMD ["./app/target/release/hello_rocket"]