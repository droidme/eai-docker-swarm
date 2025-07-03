#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_swarm() {
    if ! docker info | grep -q "Swarm: active"; then
        print_warning "Docker Swarm ist nicht aktiv. Initialisiere Swarm..."
        docker swarm init
        print_status "Docker Swarm wurde initialisiert"
    else
        print_status "Docker Swarm ist bereits aktiv"
    fi
}

build_adapters() {
    print_status "Baue EAI Adapter Images..."
    
    cd eai-adapters/sample
    if [ -f "pom.xml" ]; then
        mvn clean package -DskipTests
        docker build -t eai-adapter-sample:latest .
        print_status "Sample Adapter Image erstellt"
    fi
    cd ../..
    
    cd eai-adapters/orders
    if [ -f "pom.xml" ]; then
        mvn clean package -DskipTests
        docker build -t eai-adapter-orders:latest .
        print_status "Orders Adapter Image erstellt"
    fi
    cd ../..
}

deploy_stack() {
    print_status "Deploye EAI Stack..."
    docker stack deploy -c docker-compose.yml eai-stack
    
    print_status "Warte auf Service-Start..."
    sleep 30
    
    print_status "Service Status:"
    docker service ls
}

show_urls() {
    print_status "Deployment abgeschlossen! Zugriff über folgende URLs:"
    echo ""
    echo "Traefik Dashboard: http://localhost:8080"
    echo "Prometheus:        http://localhost:9090"
    echo "Grafana:          http://localhost:3000 (admin/admin)"
    echo "Sample Adapter:    http://localhost/api/health (oder adapter-sample.localhost)"
    echo "Orders Adapter:    http://localhost/api/health (oder adapter-orders.localhost)"
    echo ""
    echo "Fügen Sie folgende Einträge zu /etc/hosts hinzu:"
    echo "127.0.0.1 traefik.localhost prometheus.localhost grafana.localhost"
    echo "127.0.0.1 adapter-sample.localhost adapter-orders.localhost"
}

cleanup() {
    print_status "Räume EAI Stack auf..."
    docker stack rm eai-stack
    sleep 10
    print_status "Stack wurde entfernt"
}

case "${1:-deploy}" in
    "deploy")
        check_swarm
        build_adapters
        deploy_stack
        show_urls
        ;;
    "cleanup")
        cleanup
        ;;
    "status")
        docker service ls
        docker stack ps eai-stack
        ;;
    *)
        echo "Usage: $0 {deploy|cleanup|status}"
        exit 1
        ;;
esac
