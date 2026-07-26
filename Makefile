SHELL := cmd.exe
APP_NAME := openlist
TAGS     := jsoniter

# Override at build time, e.g. make build-linux-amd64 VERSION=v4.2.4 WEB_VERSION=v4.2.4
VERSION     ?= dev
WEB_VERSION ?= rolling
GIT_COMMIT  := $(shell git rev-parse --short HEAD 2>nul)
ifeq ($(GIT_COMMIT),)
GIT_COMMIT := unknown
endif
# No spaces: cmd/go linker splits -ldflags on whitespace
BUILT_AT := $(shell powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'")

LDFLAGS := -s -w \
	-X github.com/OpenListTeam/OpenList/v4/internal/conf.BuiltAt=$(BUILT_AT) \
	-X github.com/OpenListTeam/OpenList/v4/internal/conf.GitCommit=$(GIT_COMMIT) \
	-X github.com/OpenListTeam/OpenList/v4/internal/conf.Version=$(VERSION) \
	-X github.com/OpenListTeam/OpenList/v4/internal/conf.WebVersion=$(WEB_VERSION)

.PHONY: build-linux-amd64 build-linux-arm64 build-win64 clean

build-linux-amd64:
	set GOOS=linux&& set GOARCH=amd64&& go build -tags=$(TAGS) -ldflags="$(LDFLAGS)" -o $(APP_NAME) .

build-linux-arm64:
	set GOOS=linux&& set GOARCH=arm64&& go build -tags=$(TAGS) -ldflags="$(LDFLAGS)" -o $(APP_NAME) .

build-win64:
	go build -tags=$(TAGS) -ldflags="$(LDFLAGS)" -o $(APP_NAME).exe .

clean:
	-del /q $(APP_NAME) 2>nul
	-del /q $(APP_NAME).exe 2>nul
	go clean -cache
