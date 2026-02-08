#!/usr/bin/env bash
# https://github.com/originalankur/maptoposter
# Read the documentation to change themes and settings for each city
# Get the directory where THIS script is located SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd) cd "$SCRIPT_DIR" || exit 1
# TODO: kolkata is done already, change to some other city both here and on that notepad.pw link in Chrome readonly CITY="kolkata" readonly COUNTRY="india"
readonly CONTAINER_NAME="map_to_poster"

if ! docker buildx build \ --file "Dockerfile" \ --progress none \ --tag "${CONTAINER_NAME}" \ --quiet .; then
  printf "Error: %s" "while attempting to build the docker container:${CONTAINER_NAME}"
  exit 1
fi

if ! docker container run \ --detach \ --interactive \ --name "${CONTAINER_NAME}" \ --tty \ "${CONTAINER_NAME}"; then
  printf "Error: %s" "while attempting to run the docker container:${CONTAINER_NAME}"
  exit 1
fi

container_id=$(docker ps -aqf "name=${CONTAINER_NAME}")
if [ -z "$container_id" ]; then
  echo "Container not found!"
else
  echo "The ID for ${CONTAINER_NAME} is: $container_id"
fi

docker exec -i "${CONTAINER_NAME}" bash -c "cd /home/python/app/maptoposter && python create_map_poster.py --city '${CITY}' --country '${COUNTRY}'"

mkdir -p "${HOME}/map_to_poster"
if ! docker cp "${container_id}":/home/python/app/maptoposter/posters "${HOME}/map_to_poster"; then
  printf "Error: %s" "while attempting to copy map files from container:${CONTAINER_NAME}"
fi

if ! docker stop "${CONTAINER_NAME}"; then
  printf "Error: %s" "stopping container:${CONTAINER_NAME}"
fi

if ! docker rm "${CONTAINER_NAME}"; then
  printf "Error: %s" "removing container:${CONTAINER_NAME}"
fi