FROM node:20 as step1
RUN mkdir /kitsune && \
    cd /kitsune && \
    curl https://github.com/kitsune-soc/kitsune/archive/refs/heads/main.zip -Lo main.zip && \
    unzip main.zip && \
    cd kitsune-main/kitsune-fe && \
    yarn install && \
    yarn build

FROM messense/rust-musl-cross:x86_64-musl as step2
COPY --from=step1 /kitsune/kitsune-main /home/rust/src
WORKDIR /home/rust/src
RUN --mount=type=cache,target=/home/rust/src/target \
    --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,target=/root/.cargo/git \
    cargo build --release -p kitsune -p kitsune-cli -p kitsune-job-runner --features oidc && \
    mv /home/rust/src/target/x86_64-unknown-linux-musl/release/kitsune /kitsune && \
    mv /home/rust/src/target/x86_64-unknown-linux-musl/release/kitsune-cli /kitsune-cli && \
    mv /home/rust/src/target/x86_64-unknown-linux-musl/release/kitsune-job-runner /kitsune-job-runner

FROM scratch
COPY --from=step1 /kitsune/kitsune-main/kitsune-fe/dist /kitsune-fe
COPY --from=step2 /kitsune /kitsune-
COPY --from=step2 /kitsune /kitsune
COPY --from=step2 /kitsune-cli /kitsune-cli
COPY --from=step2 /kitsune-job-runner /kitsune-job-runner
COPY --from=alpine:latest /lib/ld-musl-x86_64.so.1 /lib/ld-musl-x86_64.so.1
COPY --from=alpine:latest /bin/ash /ash
COPY --from=alpine:latest /bin/cat /cat
COPY --from=alpine:latest /etc/ssl /etc/ssl
COPY --from=hairyhenderson/gomplate:stable /gomplate /gomplate
COPY config.tpl.toml /config.tpl.toml
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
