# Hands-On Lab Session: Virtual Lab Setup and Basic Traffic Analysis

## Introduction

### Objectives

- Set up virtual lab environment with Docker
- Capture traffic between client and web_server
- analyze the traffic in wireshark

### Overview

In this practice, we will set up a virtual lab environment using Docker. Two containers will be created: the first one as a client and the second one as a web server. After running the Docker containers, we will capture the network traffic between the client and the web server during their communication. Finally, we will analyze the captured traffic using Wireshark.

## Methodology

### Set Up Virtual Lab Environment with Docker Compose

The first requirement is Docker, so ensure that Docker is installed on the system.  
Next, save the following code as a `docker-compose.yml` file:

```yaml
version: "3.8"
services:
  web_server:
    image: nginx:latest
    container_name: web_server
    networks:
      - my_network
  client:
    image: ubuntu:latest
    container_name: client
    tty: true # Keeps the container running interactively
    networks:
      - my_network
    command: bash # Starts an interactive shell

networks:
  my_network:
    driver: bridge
```

To launch the environment, execute the following command:
`docker-compose up -d`

## Discussion

During this practice, I encountered some problem,

- curl and nmap were not installed on the client container
  ![Tools Not Installed](images/tools_not_installed.png)
- Windows could not capture traffic between container

To resolve the first issue, I created a new Dockerfile for the client. This ensures that the necessary tools are pre-installed, eliminating the need to reinstall them every time we rerun docker-compose. Below is the Dockerfile and the modified line in docker-compose.yml.

- client.Dockerfile

```dockerfile
FROM ubuntu:latest

RUN apt update && apt install nmap curl iputils-ping -y

```

- docker-compose.yml

```yml
version: "3.8"
services:
  web_server:
    image: nginx:latest
    container_name: web_server
    networks:
      - my_network
  client:
    build:
      context: client
      dockerfile: client.Dockerfile
    container_name: client
    tty: true
    networks:
      - my_network
    command: bash
networks:
  my_network:
    driver: bridge
```

To resolve the second issue, I used the web_server container to capture network traffic and saved it to a directory that is bound to a Windows directory. Additionally, I created a new Dockerfile and modified the Docker Compose file to implement this solution.

- web.Dockerfile

```dockerfile
FROM nginx:latest

RUN apt update && apt install tcpdump -y
```

- docker-compose.yml

```yml
version: "3.8"
services:
  web_server:
    build:
      context: web_server
      dockerfile: web.Dockerfile
    container_name: web_server
    volumes:
      - ./result:/output:rw
    networks:
      - my_network
  client:
    build:
      context: client
      dockerfile: client.Dockerfile
    container_name: client
    tty: true
    networks:
      - my_network
    command: bash
networks:
  my_network:
    driver: bridge
```

## Results and Analysis

_(Present the findings from the lab session. Use bullet points, tables, or code snippets if necessary.)_

## Conclusion

_(Summarize key takeaways, learning points, and any recommendations for future improvements.)_
