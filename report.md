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

### Run Listener

For the listener, I use tcpdump that will be listening in web_server container. here's the syntax to set the listener

```bash
tcpdump -i eth0 tcp -w /output/curlTest.pcap
```

```bash
tcpdump -i eth0 -w /output/nmapTest.pcap
```

## Discussion

During this practice, I encountered some problem,

- curl and nmap were not installed on the client container
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

### Results

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

- nmapTest.pcap

```bash
1   0.000000 02:42:ac:12:00:03 → Broadcast    ARP 42 Who has 172.18.0.2? Tell 172.18.0.3
2   0.000005 02:42:ac:12:00:02 → 02:42:ac:12:00:03 ARP 42 172.18.0.2 is at 02:42:ac:12:00:02
3   0.149812   172.18.0.3 → 172.18.0.2   TCP 58 45117 → 80 [SYN] Seq=0 Win=1024 Len=0 MSS=1460
4   0.149841   172.18.0.2 → 172.18.0.3   TCP 58 80 → 45117 [SYN, ACK] Seq=0 Ack=1 Win=64240 Len=0 MSS=1460
5   0.149868   172.18.0.3 → 172.18.0.2   TCP 54 45117 → 80 [RST] Seq=1 Win=0 Len=0
6   0.300728   172.18.0.3 → 172.18.0.2   TCP 74 46842 → 80 [SYN] Seq=0 Win=64240 Len=0 MSS=1460 SACK_PERM=1 TSval=86156069 TSecr=0 WS=128
7   0.300764   172.18.0.2 → 172.18.0.3   TCP 74 80 → 46842 [SYN, ACK] Seq=0 Ack=1 Win=65160 Len=0 MSS=1460 SACK_PERM=1 TSval=1953871048 TSecr=86156069 WS=128
8   0.300786   172.18.0.3 → 172.18.0.2   TCP 66 46842 → 80 [ACK] Seq=1 Ack=1 Win=64256 Len=0 TSval=86156069 TSecr=1953871048
9   5.209474 02:42:ac:12:00:02 → 02:42:ac:12:00:03 ARP 42 Who has 172.18.0.3? Tell 172.18.0.2
10   5.209531 02:42:ac:12:00:03 → 02:42:ac:12:00:02 ARP 42 172.18.0.3 is at 02:42:ac:12:00:03
11   6.306973   172.18.0.3 → 172.18.0.2   HTTP 84 GET / HTTP/1.0
12   6.307011   172.18.0.2 → 172.18.0.3   TCP 66 80 → 46842 [ACK] Seq=1 Ack=19 Win=65152 Len=0 TSval=1953877055 TSecr=86162076
13   6.307236   172.18.0.2 → 172.18.0.3   TCP 299 HTTP/1.1 200 OK  [TCP segment of a reassembled PDU]
14   6.307283   172.18.0.3 → 172.18.0.2   TCP 66 46842 → 80 [ACK] Seq=19 Ack=234 Win=64128 Len=0 TSval=86162076 TSecr=1953877055
15   6.307306   172.18.0.2 → 172.18.0.3   HTTP 681 HTTP/1.1 200 OK  (text/html)
16   6.307319   172.18.0.3 → 172.18.0.2   TCP 66 46842 → 80 [ACK] Seq=19 Ack=849 Win=63872 Len=0 TSval=86162076 TSecr=1953877055
17   6.307425   172.18.0.2 → 172.18.0.3   TCP 66 80 → 46842 [FIN, ACK] Seq=849 Ack=19 Win=65152 Len=0 TSval=1953877055 TSecr=86162076
18   6.309021   172.18.0.3 → 172.18.0.2   TCP 66 46842 → 80 [FIN, ACK] Seq=19 Ack=850 Win=64128 Len=0 TSval=86162078 TSecr=1953877055
19   6.309027   172.18.0.2 → 172.18.0.3   TCP 66 80 → 46842 [ACK] Seq=850 Ack=20 Win=65152 Len=0 TSval=1953877057 TSecr=86162078
20   6.311700   172.18.0.3 → 172.18.0.2   TCP 74 46850 → 80 [SYN] Seq=0 Win=64240 Len=0 MSS=1460 SACK_PERM=1 TSval=86162080 TSecr=0 WS=128
21   6.311732   172.18.0.2 → 172.18.0.3   TCP 74 80 → 46850 [SYN, ACK] Seq=0 Ack=1 Win=65160 Len=0 MSS=1460 SACK_PERM=1 TSval=1953877059 TSecr=86162080 WS=128
```

[Full results](https://github.com/spexf/network-security-task-01/raw/refs/heads/main/result/nmapTest.pcap)

### Analysis

- curlTest.pcap [Click to download file](https://github.com/spexf/network-security-task-01/raw/refs/heads/main/result/curlTest.pcap)

From lines 1 to 3, we can observe the container performing a three-way handshake on port 80, which occurs at layer 4. In line 4, the client sends a GET / HTTP/1.1 request to retrieve the home page. Then, in line 8, the web_server sends the web page with a 200 OK status, which occurs at layer 7. Finally, from lines 9 to 12, the communication is gracefully terminated.

- nmapTest.pcap [Click to download file](https://github.com/spexf/network-security-task-01/raw/refs/heads/main/result/nmapTest.pcap)

In this capture, communication begins with ARP exchanges at Layer 2. The client sends a TCP SYN at Layer 4 to initiate a connection to port 80. The server responds with a SYN-ACK, but the client sends a RST to cancel the initial attempt. A new TCP handshake is then successfully completed at Layer 4. Next, the client sends a GET request at Layer 7 to retrieve the home page, and the server responds with HTTP 200 OK and the webpage content at Layer 7. Finally, the connection is closed gracefully with FIN and ACK packets at Layer 4, and several new TCP connections are initiated. Additionally, since I executed Nmap with the -sC option, default scripts ran to gather further information about the scanned ports. In this capture, the communication usually happen in layer 2, 4, 7.

## Conclusion

In summary, this lab session effectively showcased the process of establishing a virtual lab environment through Docker, capturing network traffic, and examining the data using Wireshark. We addressed challenges such as missing tools on the client container and issues capturing traffic on Windows by customizing Docker images and adjusting our configurations. The traffic examination confirmed the correct functionality of network protocols across various OSI layers—from ARP at Layer 2 and TCP negotiations at Layer 4 to HTTP exchanges at Layer 7. Moreover, executing Nmap with the -sC flag offered additional information about the inspected ports with cost that many request will be established to web_server. Overall, this exercise reinforced our understanding of containerized network environments and the importance of detailed traffic analysis in network security tasks.

#### ([RKSA 2023 | Muhammad Ath Thoriq Kurnia Ramadhan | 4332301013](https://github.com/spexf/network-security-task-01/tree/main))
