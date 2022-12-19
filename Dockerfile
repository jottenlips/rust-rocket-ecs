FROM rust:1.63.0

ENV ROCKET_ADDRESS=0.0.0.0
ENV ROCKET_PORT=3000

WORKDIR /app
COPY . .

EXPOSE 3000

RUN rustup default nightly
RUN cargo build

CMD ["cargo", "run"]