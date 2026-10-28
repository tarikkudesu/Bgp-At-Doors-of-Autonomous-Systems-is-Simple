LOGIN			=	tamehri
NETWORKS		=	$$(docker network ls -q --filter "type=custom")
IMAGES			=	$$(docker image ls -aq)
VOLUMES			=	$$(docker volume ls -q)
CONTAINERS		=	$$(docker ps -aq)
COMPOSEFILE		=	srcs/docker-compose.yml
GREEN			=	\033[0;32m
RESET			=	\033[0m
cols			=	$$(tput cols)
SE				=	$$(printf "%-$(cols)s" "_" | tr ' ' '_')

HOST1			=	ebd83dfd3fbf
HOST2			=	70d576a14fb0
ROUTER1			=	7b340dcda3d8
ROUTER2			=	b04cd23732b1

all: up

up:
	@LOGIN=$(LOGIN) docker compose -f $(COMPOSEFILE) $@ --build -d
down:
	@LOGIN=$(LOGIN) docker compose -f $(COMPOSEFILE) $@
build:
	@LOGIN=$(LOGIN) docker compose -f $(COMPOSEFILE) $@
ps:
	@LOGIN=$(LOGIN) docker compose -f $(COMPOSEFILE) $@ --all
top:
	@LOGIN=$(LOGIN) docker compose -f $(COMPOSEFILE) $@
stop:
	@LOGIN=$(LOGIN) docker compose -f $(COMPOSEFILE) $@
restart:
	@LOGIN=$(LOGIN) docker compose -f $(COMPOSEFILE) $@

setup:
	@ansible-playbook -K playbook.yml

static:
	@docker exec -i $(HOST1) sh < ./static/host_1.sh
	@docker exec -i $(HOST2) sh < ./static/host_2.sh
	@docker exec -i $(ROUTER1) sh < ./static/router_1.sh
	@docker exec -i $(ROUTER2) sh < ./static/router_2.sh

multicast:
	@docker exec -i $(HOST1) sh < ./multicast/host_1.sh
	@docker exec -i $(HOST2) sh < ./multicast/host_2.sh
	@docker exec -i $(ROUTER1) sh < ./multicast/router_1.sh
	@docker exec -i $(ROUTER2) sh < ./multicast/router_2.sh

ls:
	@echo $(SE) && docker images && echo $(SE) && docker ps --all
	@echo $(SE) && docker volume ls && echo $(SE) && docker network ls --filter "type=custom"

cleancontainers:
	@echo -n " ✔ cleaning containers ..."
	@docker stop $(CONTAINERS) > /dev/null 2>&1 || true
	@docker rm -f $(CONTAINERS) > /dev/null 2>&1 || true
	@echo "$(GREEN)\tDone$(RESET)"
cleanimages:
	@echo -n " ✔ cleaning images ..."
	@docker image rm -f $(IMAGES) > /dev/null 2>&1 || true
	@echo "$(GREEN)\t\tDone$(RESET)"
cleannetworks:
	@echo -n " ✔ cleaning networks ..."
	@docker network rm -f $(NETWORKS) > /dev/null 2>&1 || true
	@echo "$(GREEN)\tDone$(RESET)"
cleanvolumes:
	@echo -n " ✔ cleaning volumes ..."
	@docker volume rm -f $(VOLUMES) > /dev/null 2>&1 || true
	@echo "$(GREEN)\t\tDone$(RESET)"

clean: cleancontainers cleanimages cleannetworks

fclean: clean cleanvolumes

prune: fclean
	@echo -n " ✔ system prune ..."
	@docker system prune --all --force > /dev/null 2>&1 || true
	@echo "$(GREEN)\t\tDone$(RESET)"

re: fclean up

.PHONY: up down build ps top stop restart static multicast ls cleancontainers cleanimages cleannetworks cleanvolumes clean fclean prune re