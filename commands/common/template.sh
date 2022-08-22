HBS_IMAGE=${HBS_IMAGE:-hbs:${HBS_VERSION:-latest}}

function template_render() {
	local SOURCE_PATH="$(realpath -s "${1}")"
	local TARGET_PATH="$(realpath -s ${2:-${SOURCE_PATH}})"
	local TMPDIR=$(mktemp -d)

	local DATA_PATH=${TMPDIR}/data.json
	cat - >"${DATA_PATH}"

	local DOCKERFILE_PATH=${TMPDIR}/Dockerfile
	local DOCKERCOMPOSE_PATH=${TMPDIR}/docker-compose.yml
	local ENTRYPOINT_PATH=${TMPDIR}/hbs

	cat <<-'EOF' >"${ENTRYPOINT_PATH}"
	#!/usr/bin/env bash

	./node_modules/.bin/hbs ${*} 2>&1 | sed -e 's#.result from# from#'

	while [[ $# -gt 0 ]]; do
		case $1 in
		--output|-o)
			OUTPUT="$2"
			shift # consume argument
			shift # consume value
			;;
		*)
			shift
			;;
		esac
	done

	find "${OUTPUT}" -maxdepth 1 -name '*.result' -exec sh -c 'f="{}"; mv "$f" "${f%.result}"' \;
	EOF
	chmod a+x "${ENTRYPOINT_PATH}"

	cat <<-'EOF' >"${DOCKERFILE_PATH}"
	FROM node:16-slim

	WORKDIR /app
	RUN npm install --save-dev hbs-cli \
		&& npm cache clean --force

	USER 1000:1000
	COPY hbs /app/hbs

	ENTRYPOINT [ "/app/hbs" ]
	EOF

	cat <<-EOF >"${DOCKERCOMPOSE_PATH}"
	version: '3'
	services:
	  hbs:
	    image: ${HBS_IMAGE}
	    build:
	      context: .
	      dockerfile: ${DOCKERFILE_PATH}
	      args:
	      - HTTP_PROXY
	      - HTTPS_PROXY
	      - NO_PROXY
	    network_mode: "none"
	EOF

	docker-compose -f "${DOCKERCOMPOSE_PATH}" run --rm \
		-v "${DATA_PATH}":/data.json \
		-v "${SOURCE_PATH}":"${SOURCE_PATH}" \
		-v "${TARGET_PATH}":"${TARGET_PATH}" \
		--user "$(id -u):$(id -g)" \
		hbs -e result -D /data.json -o "${TARGET_PATH}" -- "${SOURCE_PATH}"/*.hbs

	rm -rf "${TMPDIR}"
}
