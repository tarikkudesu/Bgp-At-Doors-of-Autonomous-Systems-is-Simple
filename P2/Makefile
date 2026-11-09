HOST1			=	
HOST2			=	
ROUTER1			=	
ROUTER2			=	

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

.PHONY: static multicast
