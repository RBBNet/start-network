HBS_IMAGE=${HBS_IMAGE:-hbs:${HBS_VERSION:-latest}}

function template_render() {
	local SOURCE_PATH="$(realpath -s "${1}")"
	local TARGET_PATH="$(realpath -s ${2:-${SOURCE_PATH}})"
	local TMPDIR=$(mktemp -d)
	local DATA_PATH=${TMPDIR}/data.json
	cat - >"${DATA_PATH}"

	local DOCKERFILE_PATH=${TMPDIR}/Dockerfile
	local DOCKERCOMPOSE_PATH=${TMPDIR}/docker-compose.yml

	cat <<-'EOF' >"${DOCKERFILE_PATH}"
		FROM node:16-slim

		WORKDIR /app
		RUN npm install --save-dev hbs-cli \
			&& npm cache clean --force

		ENTRYPOINT [ "/app/node_modules/.bin/hbs" ]
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
	EOF

	docker-compose -f "${DOCKERCOMPOSE_PATH}" run --rm \
		-v "${DATA_PATH}":/data.json \
		-v "${SOURCE_PATH}":"${SOURCE_PATH}" \
		-v "${TARGET_PATH}":"${TARGET_PATH}" \
		hbs -e result -D /data.json -o "${TARGET_PATH}" -- "${SOURCE_PATH}"/*.hbs 2> >(sed -e 's#.result from# from#')

	rename .result '' "${TARGET_PATH}"/*.result

	rm -rf "${TMPDIR}"
}
