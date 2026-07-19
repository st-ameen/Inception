SRC = srcs/docker-compose.yml
NAME = docker
ENV_FILE = srcs/.env
DATA_PATH := $(shell grep -E '^DATA_PATH=' $(ENV_FILE) | head -n1 | cut -d= -f2-)


all: $(NAME)

$(NAME): $(SRC)
	sudo mkdir -p "$(DATA_PATH)/mariadb" "$(DATA_PATH)/wordpress" "$(DATA_PATH)/portainer"
	sudo docker compose -p inception --env-file $(ENV_FILE) -f $(SRC) up -d --build

clean:
	sudo docker compose -p inception --env-file $(ENV_FILE) -f $(SRC) down

restart: clean all

remove: clean
	sudo docker compose -p inception --env-file $(ENV_FILE) -f $(SRC) down --volumes --remove-orphans


wipe: clean
	sudo docker system prune -a --volumes

fclean: clean
	sudo rm -rf "$(DATA_PATH)"

re : fclean all