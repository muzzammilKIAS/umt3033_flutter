# Build context is the repo root (see render.yaml's dockerContext) so this
# can reach packages/game_shared, the path dependency server/pubspec.yaml
# needs.
FROM dart:stable AS build
WORKDIR /app
COPY packages/game_shared /app/packages/game_shared
COPY server/pubspec.yaml server/pubspec.lock* /app/server/
WORKDIR /app/server
RUN dart pub get
COPY server /app/server
RUN dart pub get --offline
RUN dart compile exe bin/main.dart -o /app/server/bin/game_server

# scratch (not debian-slim) so copying /runtime/ onto / doesn't collide with
# debian's merged-usr symlinks (e.g. /lib -> /usr/lib), which made this fail
# on Render with "cannot copy to non-directory: .../lib". The server makes
# no outbound HTTPS calls, so it needs no CA certificates either.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/server/bin/game_server /app/game_server
EXPOSE 8080
CMD ["/app/game_server"]
