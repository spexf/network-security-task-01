FROM ubuntu:latest

WORKDIR /

RUN apt update && apt install nmap curl iputils-ping -y
