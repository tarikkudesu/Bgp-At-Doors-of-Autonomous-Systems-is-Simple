
all: setup

setup:
	@ansible-playbook -K playbook.yml

.PHONY setup
