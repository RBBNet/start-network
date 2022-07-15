function json_array() {
	jq --raw-input --slurp 'split("\n") | map(select(. != ""))'
}
