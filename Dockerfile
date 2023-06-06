# syntax=docker/dockerfile:1

FROM golang:1.20 AS deps

WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download

FROM deps AS version

COPY .git/ .git/
RUN git describe --tags | sed -e 's,^v,,' > /version

FROM deps AS build
COPY --from=version /version /version

COPY . ./

ENV CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH}
RUN go build -o /locker -ldflags="-X main.Version=$(cat /version)"  ./ 

FROM scratch

COPY --from=build /locker /locker

ENV PORT=3000 LOCKER_CONFIG=/tmp/locker-data.yaml
CMD ["/locker"]
