BESU_PRIVATE_KEY_FILENAME="key"
BESU_PUBLIC_KEY_FILENAME="key.pub"
BESU_NODE_ADDRESS_FILENAME="node.address"

function besu_generate_keypair() {
	local NODE_CONFIG_PATH="${1}"

	chown -R 1000 "${NODE_CONFIG_PATH}"
	cat <<-EOF | docker run --rm -i -v "$(realpath ${NODE_CONFIG_PATH}):/var/lib/besu/" --entrypoint=/bin/bash ${IMAGE_BESU:-hyperledger/besu}
		besu public-key export --to=/var/lib/besu/${BESU_PUBLIC_KEY_FILENAME}
		besu public-key export-address --to=/var/lib/besu/${BESU_NODE_ADDRESS_FILENAME}
		mv /opt/besu/key /var/lib/besu/
	EOF
}

function besu_get_publickey() {
	local NODE_CONFIG_PATH="${1}"
	chown -R 1000 "${NODE_CONFIG_PATH}"
	if [[ -f "${NODE_CONFIG_PATH}/${BESU_PUBLIC_KEY_FILENAME}" ]]; then
		cat "${NODE_CONFIG_PATH}/${BESU_PUBLIC_KEY_FILENAME}"
		echo
	else
		docker run --rm -i -v "$(realpath ${NODE_CONFIG_PATH}):/var/lib/besu/" ${IMAGE_BESU:-hyperledger/besu} --data-path=/var/lib/besu/ public-key export |
			tail -n1 |
			tee "${NODE_CONFIG_PATH}/${BESU_PUBLIC_KEY_FILENAME}"
	fi
}

function besu_get_address() {
	local NODE_CONFIG_PATH="${1}"
	chown -R 1000 "${NODE_CONFIG_PATH}"
	if [[ -f "${NODE_CONFIG_PATH}/${BESU_NODE_ADDRESS_FILENAME}" ]]; then
		cat "${NODE_CONFIG_PATH}/${BESU_NODE_ADDRESS_FILENAME}"
		echo
	else
		docker run --rm -i -v "$(realpath ${NODE_CONFIG_PATH}):/var/lib/besu/" ${IMAGE_BESU:-hyperledger/besu} --data-path=/var/lib/besu/ public-key export-address |
			tail -n1 |
			tee "${NODE_CONFIG_PATH}/${BESU_NODE_ADDRESS_FILENAME}"
	fi
}

function besu_get_enode() {
	local NODE_CONFIG_PATH="${1}"
	local NAME=$(basename "${NODE_CONFIG_PATH}")
	local PUBKEY=$(besu_get_publickey "${NODE_CONFIG_PATH}")
	printf 'enode://%s@%s:30303\n' ${PUBKEY#0x} ${NAME}
}

function besu_format_enode() {
	local NAME=${1}
	local PUBKEY=${2}
	printf 'enode://%s@%s:30303\n' ${PUBKEY#0x} ${NAME}
}

function besu_encode_rlp() {
	docker run --rm -i ${IMAGE_BESU:-hyperledger/besu} rlp encode --type=IBFT_EXTRA_DATA
}

function besu_genesis_ready() {
	local GENESIS_PATH="${1}"
	[[ -f "${GENESIS_PATH}" && $(jq '.extraData != null' "${GENESIS_PATH}") == "true" ]]
}

function besu_genesis_base() {
	cat <<-EOF
		{
			"config": {
				"chainId": 648629,
				"constantinopleFixBlock": 0,
				"berlinBlock": 0,
				"contractSizeLimit": 2147483647,
				"ibft2": { "blockperiodseconds": 2, "epochlength": 30000, "requesttimeoutseconds": 4 },
				"discovery": { "bootnodes": [] }
			},
			"nonce": "0x0",
			"gasLimit": "0x2FEFD800",
			"difficulty": "0x1",
			"mixHash": "0x63746963616c2062797a616e74696e65206661756c7420746f6c6572616e6365",
			"coinbase": "0x0000000000000000000000000000000000000000"
		}
	EOF
}
