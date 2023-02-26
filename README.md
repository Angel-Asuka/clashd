# ClashD
This is a simple script to build a docker image to run clash in Linux.

# Prerequired
Please make a full check about the following list:
- [ ] A docker running well.

- [ ] A connection could access the Internet.

- [ ] A bash or other command-line environment could execute a bash script.

# Quick Start
Just simply execute the build script to build an image:
```bash
# Build clashd image.
./build
# Run a container using the clashd image.
docker run -d --name clash \
    -p 7890:7890 -p 9090:9090 \
    -e CONFIG_URL=YOUR-SUBSCRIPTION-URL \
    clashd
```
Now, you have a clash running on your docker system. check out the dashboard from: http://127.0.0.1:9090/ui

# Arguments for the build script
The options for the build script were listed below:
| Argument             | Type   | Description |
|----------------------|--------|-------------|
| --build-clash        | switch | Build the clash from the master branch.<br/> If this argument was specified, the script will pull the master branch from Github, and run a golang container to build the clash.<br/> Otherwise, the script will download the latest release version of the linux amd64 binary.|
| --build-dashboard    | switch | Build the dashboard from the master branch.<br/> If this argument was specified, the script will pull the mast branch from Github, and run a node container to build the dashboard.</br/> Otherwise, the script will pull the gh-pages branch directly. |
| --runtime-clash      | switch | Download the clash binary when the first time a clash container is running. <br/> If this argument was specified, the script will NOT builds nor downloads the clash in the image-building stage. |
| --runtime-geoip      | switch | Download the GeoIP's database when the first time a clash container is running. <br/> If this argument was specified, the script will NOT download the Country.mmdb file in the image-building stage. |
| --runtime-dashboard  | switch | Download the dashboard when the first time a clash container is running. <br/> If this argument was specified, the script will NOT download builds nor fetches the dashboard in the image-building stage |
| --clash-version      | string<br/>eg.'v1.20.0' | Specify the clash version you want to use. Work only when the --build-clash and --runtime-clash were not specified. |
| -t \| --tag          | string | Specify the image tag name |
| --image              | string | Specify the base image you want to use to build the clash image. By default, the script will use "ubuntu:18.04" instead. |
| --run                | string | Specify the additional commands you want to execute in the container when the image is building. |
| -f \| --config-file   | string | Specify the clash configure file you want to embed in the image. |
| -u \| --config-url    | string | Specify the URL of the clash configure file you want to embed in the image. |
| -h \| --help          | switch | Make the script shows a Usage notice like this table. |

# Environment variables for the container.
You could like to specify some environment variables for the container to make some runtime settings. This is a table of the variables you could use:

|Name|Default|Description|
|----|-----|-----------|
| MIX_PORT     |  | Specify a port the clash will listen on to serve both the http(s) and socks. If the variable was specified, both HTTP_PORT and SOCKS_PORT will be ignored. |
| HTTP_PORT    | 7890 | Specify a port the http(s) proxy will serves on |
| SOCKS_PORT   | 7891 | Specify a port the socks proxy will serves on |
| CTRL_PORT    | 9090 | Specify a port the API and dashboard will serves on |
| CONFIG_URL   |      | Specify a URL to your clash configure file. this will be ignored if you embed one in the image. |

# License
The script and this repository were published by Asuka under the MIT license. Please feel free to use, share, and make some upgrading.

Having fun on the internet.