LOGIN			=	tamehri
HOST			=	
ROUTER			=	

all: build

build:
	@LOGIN=$(LOGIN) docker compose -f srcs/docker-compose.yml $@

config:
	@docker exec -i $(HOST) sh < ./config/host.sh
	@docker exec -i $(ROUTER) sh < ./config/router.sh

.PHONY: build
