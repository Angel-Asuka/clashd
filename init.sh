#!/bin/bash

echo "clashd starting..."

COMPLETE_MARK=/etc/clash/complete
CONFIG_FILE=/etc/clash/config.yaml
GEOIP_PATH=/etc/clash/Country.mmdb
CLASH_PATH=/usr/bin/clash
UI_PATH=/usr/share/clash-dashboard

CheckLastestReleaseOfGithubReprositry() {
    local ver=$(wget --max-redirect=0 --server-response $1/releases/latest 2>&1 | grep Location | sed -nE 's/.*releases\/tag\/([^\/ ]+)$/\1/p'  | head -n 1)
    if [ -z $ver ]; then
        echo "Failed to check the lastest release of $1"
        exit 1
    fi
    echo $ver
}

# Check the clash binary exists
if [ ! -f "$CLASH_PATH" ]; then
    mkdir -p $(dirname $CLASH_PATH)
    echo "Downloading clash..."
    echo "Check the last version of clash..."
    CLASH_VERSION=$(CheckLastestReleaseOfGithubReprositry https://github.com/Dreamacro/clash)
    echo "The lastest version of clash is ${CLASH_VERSION}"

    # Check if our processor is compatible with the v3 microarchitecture.
    if [ $(grep -c avx2 /proc/cpuinfo) -gt 0 ]; then
        ARCHITECTURE=-v3
    else
        ARCHITECTURE=
    fi

    echo "Downloading clash..."
    wget https://github.com/Dreamacro/clash/releases/download/${CLASH_VERSION}/clash-linux-amd64${ARCHITECTURE}-${CLASH_VERSION}.gz -O /clash.gz 2>>/var/log/clash-init.log
    if [ $? -ne 0 ]; then
        cat "/var/log/clash-init.log"
        echo "Failed to download clash, please check the log."
        exit 1
    fi
    echo "Uncompressing clash..."
    gunzip /clash.gz
    mv /clash "$CLASH_PATH"
    chmod +x "$CLASH_PATH"
fi

# Check the GeoIP database exists
if [ ! -f "$GEOIP_PATH" ]; then
    mkdir -p $(dirname $GEOIP_PATH)
    echo "Downloading GeoIP's database ..."
    echo "Retrieving GeoIP's version ..."
    CURRENT_RELEASE=$(wget --max-redirect=0 --server-response https://github.com/Dreamacro/maxmind-geoip/releases/latest 2>&1 | grep Location | sed -nE 's/.*releases\/tag\/([0-9]+).*/\1/p')
    echo "The lastest version is ${CURRENT_RELEASE}"
    echo "Downloading GeoIP's database ..."
    wget https://github.com/Dreamacro/maxmind-geoip/releases/download/${CURRENT_RELEASE}/Country.mmdb -O "$GEOIP_PATH" 2>>/var/log/clash-init.log
    if [ $? -ne 0 ]; then
        cat "/var/log/clash-init.log"
        echo "Failed to download GeoIP's database, please check the log."
        exit 1
    fi
fi

# Check the clash-dashboard exists
if [ ! -d "$UI_PATH" ]; then
    mkdir "$UI_PATH"
    echo "Check the last version of clash-dashboard..."
    git clone -b gh-pages --depth 1 https://github.com/Dreamacro/clash-dashboard.git $UI_PATH 2>>./log
fi

# Check if the initialization is completed
if [ ! -f "$COMPLETE_MARK" ]; then
    echo "Initializing..."

    # Check the environment variables

    if [ -z "$MIX_PORT" ]; then

        if [ -z "$HTTP_PORT" ]; then
            HTTP_PORT=7890
        fi

        if [ -z "$SOCKS_PORT" ]; then
            SOCKS_PORT=7891
        fi

    fi

    if [ -z "$CTRL_PORT" ]; then
        CTRL_PORT=9090
    fi

    # Check config file
    if [ ! -f "$CONFIG_FILE" ]; then
        # Download config file if CONFIG_URL is set
        if [ ! -z "$CONFIG_URL" ]; then
            echo "Downloading config file from $CONFIG_URL"
            wget "$CONFIG_URL&flag=clash" -O "$CONFIG_FILE"
            if [ $? -ne 0 ]; then
                echo "Failed to download config file"
                exit 1
            fi
        else
            echo "Config file not found: $CONFIG_FILE"
            echo "" > "$CONFIG_FILE"
        fi
    fi

    # Patching config file

    # Remove lines starting with "external-controller" from the config file
    sed -i '/^external-controller:/d' "$CONFIG_FILE"

    # Remove lines starting with "mixed-port" from the config file
    sed -i '/^mixed-port:/d' "$CONFIG_FILE"

    # Remove lines starting with "port", "socks-port", "external-ui" from the config file
    sed -i '/^port:/d' "$CONFIG_FILE"
    sed -i '/^socks-port:/d' "$CONFIG_FILE"
    sed -i '/^external-ui:/d' "$CONFIG_FILE"
    sed -i '/^bind-address:/d' "$CONFIG_FILE"
    sed -i '/^allow-lan:/d' "$CONFIG_FILE"

    # Append the following lines to the top of config file

    sed -i "1i bind-address: 0.0.0.0" "$CONFIG_FILE"
    sed -i "1i allow-lan: true" "$CONFIG_FILE"

    sed -i "1i external-ui: $UI_PATH" "$CONFIG_FILE"

    if [ ! -z "$CTRL_PORT" ]; then
        sed -i "1i external-controller: :$CTRL_PORT" "$CONFIG_FILE"
    fi

    if [ ! -z "$MIX_PORT" ]; then
        sed -i "1i mixed-port: $MIX_PORT" "$CONFIG_FILE"
    else
        if [ ! -z "$SOCKS_PORT" ]; then
            sed -i "1i socks-port: $SOCKS_PORT" "$CONFIG_FILE"
        fi

        if [ ! -z "$HTTP_PORT" ]; then
            sed -i "1i port: $HTTP_PORT" "$CONFIG_FILE"
        fi
    fi

    # Check GeoIP database
    if [ ! -f "/etc/clash/Country.mmdb" ]; then
        # Download GeoIP database if GEOIP_URL is set
        if [ ! -z "$GEOIP_URL" ]; then
            echo "Downloading GeoIP database from $GEOIP_URL"
            curl -sSL "$GEOIP_URL" -o "/etc/clash/Country.mmdb"
            if [ $? -ne 0 ]; then
                echo "Failed to download GeoIP database"
                exit 1
            fi
        else
            echo "GeoIP database not found: /etc/clash/Country.mmdb"
        fi
    fi

    date > "$COMPLETE_MARK"

    chmod +x $CLASH_PATH
fi

# Start clash
echo "Starting clash..."
exec "$CLASH_PATH" -d "$(dirname $GEOIP_PATH)" -f "$CONFIG_FILE"
