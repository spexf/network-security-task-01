FROM nginx:latest

RUN apt update && apt install tcpdump -y