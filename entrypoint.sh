#!/ash

echo "Generating config from env"
/cat /config.tpl.toml | /gomplate -f /config.tpl.toml > /config.toml

echo "Config:"
/cat /config.toml

echo "Starting Kitsune"
/kitsune -c config.toml
