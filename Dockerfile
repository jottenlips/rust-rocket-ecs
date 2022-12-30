FROM rust:latest AS builder

RUN rustup target add x86_64-unknown-linux-musl
RUN apt update && apt install -y musl-tools musl-dev
RUN apt-get install -y build-essential
RUN yes | apt install gcc-x86-64-linux-gnu

WORKDIR /app

COPY ./ .
ENV RUSTFLAGS='-C linker=x86_64-linux-gnu-gcc'
RUN cargo build --target x86_64-unknown-linux-musl --release

FROM scratch
ENV ROCKET_ADDRESS=0.0.0.0
ENV ROCKET_PORT=8000
# Replace if you are making a real service
ENV ROCKET_SECRET_KEY="shhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh"
EXPOSE 8000
WORKDIR /app
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/hello_rocket ./
CMD ["/app/hello_rocket"]