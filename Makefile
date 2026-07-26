SHELL := cmd.exe
APP_NAME := openlist
TAGS     := jsoniter
LDFLAGS  := -s -w

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
