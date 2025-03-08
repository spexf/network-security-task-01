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

This is the directory structure after the modification

```bash
network-traffic-lab
├── client
│   └── client.Dockerfile
├── docker-compose.yml
├── result
│   ├── curlTest.pcap
│   └── nmapTest.pcap
└── web_server
    └── web.Dockerfile
```

## Results and Analysis

- curlTest.pcap

```bash
1   0.000000   172.18.0.3 → 172.18.0.2   TCP 74 60498 → 80 [SYN] Seq=0 Win=64240 Len=0 MSS=1460 SACK_PERM=1 TSval=86039781 TSecr=0 WS=128
2   0.000030   172.18.0.2 → 172.18.0.3   TCP 74 80 → 60498 [SYN, ACK] Seq=0 Ack=1 Win=65160 Len=0 MSS=1460 SACK_PERM=1 TSval=1953754760 TSecr=86039781 WS=128
3   0.000050   172.18.0.3 → 172.18.0.2   TCP 66 60498 → 80 [ACK] Seq=1 Ack=1 Win=64256 Len=0 TSval=86039781 TSecr=1953754760
4   0.000131   172.18.0.3 → 172.18.0.2   HTTP 139 GET / HTTP/1.1
5   0.000136   172.18.0.2 → 172.18.0.3   TCP 66 80 → 60498 [ACK] Seq=1 Ack=74 Win=65152 Len=0 TSval=1953754760 TSecr=86039781
6   0.000267   172.18.0.2 → 172.18.0.3   TCP 304 HTTP/1.1 200 OK  [TCP segment of a reassembled PDU]
7   0.000297   172.18.0.3 → 172.18.0.2   TCP 66 60498 → 80 [ACK] Seq=74 Ack=239 Win=64128 Len=0 TSval=86039781 TSecr=1953754760
8   0.000569   172.18.0.2 → 172.18.0.3   HTTP 681 HTTP/1.1 200 OK  (text/html)
9   0.000601   172.18.0.3 → 172.18.0.2   TCP 66 60498 → 80 [ACK] Seq=74 Ack=854 Win=64128 Len=0 TSval=86039781 TSecr=1953754760
10   0.000711   172.18.0.3 → 172.18.0.2   TCP 66 60498 → 80 [FIN, ACK] Seq=74 Ack=854 Win=64128 Len=0 TSval=86039781 TSecr=1953754760
11   0.000760   172.18.0.2 → 172.18.0.3   TCP 66 80 → 60498 [FIN, ACK] Seq=854 Ack=75 Win=65152 Len=0 TSval=1953754760 TSecr=86039781
12   0.000780   172.18.0.3 → 172.18.0.2   TCP 66 60498 → 80 [ACK] Seq=75 Ack=855 Win=64128 Len=0 TSval=86039781 TSecr=1953754760
```

- nmapTest.pcap [File PCAP](result/nmapTest.pcap)

## Conclusion

_(Summarize key takeaways, learning points, and any recommendations for future improvements.)_
