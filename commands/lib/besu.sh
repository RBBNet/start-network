BESU_PRIVATE_KEY_FILENAME="key"
BESU_PUBLIC_KEY_FILENAME="key.pub"
BESU_NODE_ID_FILENAME="node.id"

LOG4J_CONFIGURATION_FILE="/var/lib/besu/logging-off.xml"

function besu_generate_keypair() {
	local NODE_CONFIG_PATH="${1}"

	besu public-key export --to=${NODE_CONFIG_PATH}/${BESU_PUBLIC_KEY_FILENAME}
	besu public-key export-address --to=${NODE_CONFIG_PATH}/${BESU_NODE_ID_FILENAME}
	mv /opt/besu/key ${NODE_CONFIG_PATH}/
}

function besu_get_publickey() {
	local NODE_CONFIG_PATH="${1}"
	if [[ -f "${NODE_CONFIG_PATH}/${BESU_PUBLIC_KEY_FILENAME}" ]]; then
		cat "${NODE_CONFIG_PATH}/${BESU_PUBLIC_KEY_FILENAME}"
		echo
	else
		env LOG4J_CONFIGURATION_FILE="${LOG4J_CONFIGURATION_FILE}" besu --data-path=${NODE_CONFIG_PATH} public-key export |
			tee "${NODE_CONFIG_PATH}/${BESU_PUBLIC_KEY_FILENAME}"
	fi
}

function besu_get_id() {
	local NODE_CONFIG_PATH="${1}"
	if [[ -f "${NODE_CONFIG_PATH}/${BESU_NODE_ID_FILENAME}" ]]; then
		cat "${NODE_CONFIG_PATH}/${BESU_NODE_ID_FILENAME}"
		echo
	else
		env LOG4J_CONFIGURATION_FILE="${LOG4J_CONFIGURATION_FILE}" besu --data-path=${NODE_CONFIG_PATH} public-key export-address |
			tee "${NODE_CONFIG_PATH}/${BESU_NODE_ID_FILENAME}"
	fi
}

function besu_get_enode() {
	local NODE_CONFIG_PATH="${1}"
	local ADDRESS=${2:-$(basename "${NODE_CONFIG_PATH}")}
	local PUBKEY=$(besu_get_publickey "${NODE_CONFIG_PATH}")
	printf 'enode://%s@%s\n' ${PUBKEY#0x} ${ADDRESS}
}

function besu_encode_rlp() {
	local TYPE=${1:-"QBFT_EXTRA_DATA"}
	env LOG4J_CONFIGURATION_FILE="${LOG4J_CONFIGURATION_FILE}" besu rlp encode --type=${TYPE}
}

function besu_genesis_ready() {
	local GENESIS_PATH="${1}"
	[[ -f "${GENESIS_PATH}" && $(jq '.extraData != null' "${GENESIS_PATH}") == "true" ]]
}
