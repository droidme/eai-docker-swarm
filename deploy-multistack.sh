#!/bin/bash

# EAI Docker Swarm Multi-Stack Deployment Script
set -e

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}EAI Docker Swarm Multi-Stack Deployment Script${NC}"
echo "=================================================="

# Funktionen
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_section() {
    echo -e "${BLUE}[SECTION]${NC} $1"
}

# Überprüfen ob Docker Swarm initialisiert ist
check_swarm() {
    print_status "Überprüfe Docker Swarm Status..."
    if ! docker info | grep -q "Swarm: active"; then
        print_warning "Docker Swarm ist nicht aktiv. Initialisiere Swarm..."
        docker swarm init
        print_status "Docker Swarm wurde initialisiert"
    else
        print_status "Docker Swarm ist bereits aktiv"
    fi
}

# Netzwerke erstellen
create_networks() {
    print_status "Erstelle Overlay-Netzwerke..."
    
    # EAI Network für EAI-Services
    if ! docker network ls | grep -q "eai-network"; then
        docker network create --driver overlay --attachable eai-network
        print_status "EAI-Network erstellt"
    else
        print_status "EAI-Network existiert bereits"
    fi
    
    # Monitoring Network für Monitoring-Services
    if ! docker network ls | grep -q "monitoring-network"; then
        docker network create --driver overlay --attachable monitoring-network
        print_status "Monitoring-Network erstellt"
    else
        print_status "Monitoring-Network existiert bereits"
    fi
}

# Secrets erstellen
create_secrets() {
    print_status "Erstelle Docker Secrets..."
    
    # Config DB Password
    if ! docker secret ls | grep -q "config_db_password"; then
        echo "eai-config-db-secret-password" | docker secret create config_db_password -
        print_status "Config DB Secret erstellt"
    fi
}

# EAI Adapter Images bauen
build_adapter_images() {
    print_status "Baue EAI Adapter Images..."
    
    if [ -d "./eai-adapters/sample" ]; then
        cd eai-adapters/sample
        if [ -f "pom.xml" ]; then
            mvn clean package -DskipTests
            docker build -t eai-adapter-sample:latest .
            print_status "Sample Adapter Image erstellt"
        fi
        cd ../..
    fi
    
    if [ -d "./eai-adapters/orders" ]; then
        cd eai-adapters/orders
        if [ -f "pom.xml" ]; then
            mvn clean package -DskipTests
            docker build -t eai-adapter-orders:latest .
            print_status "Orders Adapter Image erstellt"
        fi
        cd ../..
    fi
    
    if [ -d "./eai-adapters/products" ]; then
        cd eai-adapters/products
        if [ -f "pom.xml" ]; then
            mvn clean package -DskipTests
            docker build -t eai-adapter-products:latest .
            print_status "Products Adapter Image erstellt"
        fi
        cd ../..
    fi
}

# Infrastructure Stack deployen
deploy_infrastructure_stack() {
    print_section "Deploye Infrastructure Stack..."
    
    if [ ! -f "infrastructure-stack.yml" ]; then
        print_error "infrastructure-stack.yml nicht gefunden!"
        exit 1
    fi
    
    docker stack deploy -c infrastructure-stack.yml infrastructure-stack
    print_status "Infrastructure Stack deployed"
    
    print_status "Warte auf Infrastructure Services..."
    sleep 30
    
    # Warten bis Traefik verfügbar ist
    local retries=0
    while ! curl -s http://localhost:8080/api/rawdata > /dev/null 2>&1; do
        retries=$((retries + 1))
        if [ $retries -gt 20 ]; then
            print_error "Traefik ist nach 3 Minuten nicht verfügbar"
            break
        fi
        print_status "Warte auf Traefik... (Versuch $retries/20)"
        sleep 10
    done
    
    print_status "Infrastructure Stack ist bereit!"
}

# Monitoring Stack deployen
deploy_monitoring_stack() {
    print_section "Deploye Monitoring Stack..."
    
    if [ ! -f "monitoring-stack.yml" ]; then
        print_error "monitoring-stack.yml nicht gefunden!"
        exit 1
    fi
    
    docker stack deploy -c monitoring-stack.yml monitoring-stack
    print_status "Monitoring Stack deployed"
    
    print_status "Warte auf Monitoring Services..."
    sleep 45
    
    # Warten bis Prometheus verfügbar ist
    local retries=0
    while ! curl -s http://localhost:9090/-/healthy > /dev/null 2>&1; do
        retries=$((retries + 1))
        if [ $retries -gt 30 ]; then
            print_error "Prometheus ist nach 5 Minuten nicht verfügbar"
            break
        fi
        print_status "Warte auf Prometheus... (Versuch $retries/30)"
        sleep 10
    done
    
    print_status "Monitoring Stack ist bereit!"
}

# EAI Stack deployen
deploy_eai_stack() {
    print_section "Deploye EAI Stack..."
    
    if [ ! -f "eai-stack.yml" ]; then
        print_error "eai-stack.yml nicht gefunden!"
        exit 1
    fi
    
    docker stack deploy -c eai-stack.yml eai-stack
    print_status "EAI Stack deployed"
    
    print_status "Warte auf EAI Services..."
    sleep 30
    
    # Health Check für EAI Adapter
    local adapters=("sample" "orders" "products")
    for adapter in "${adapters[@]}"; do
        local retries=0
        while ! curl -s http://adapter-${adapter}.localhost/actuator/health > /dev/null 2>&1; do
            retries=$((retries + 1))
            if [ $retries -gt 20 ]; then
                print_warning "Adapter ${adapter} ist nach 3 Minuten nicht verfügbar"
                break
            fi
            print_status "Warte auf ${adapter} Adapter... (Versuch $retries/20)"
            sleep 10
        done
    done
    
    print_status "EAI Stack ist bereit!"
}

# Service Status überprüfen
check_services() {
    print_section "Service Status:"
    echo ""
    echo "=== INFRASTRUCTURE STACK ==="
    docker service ls --filter label=infrastructure.stack=true
    echo ""
    echo "=== MONITORING STACK ==="
    docker service ls --filter label=monitoring.stack=true
    echo ""
    echo "=== EAI STACK ==="
    docker service ls --filter label=eai.adapter.type
    echo ""
    echo "=== ALLE STACKS ==="
    docker stack ls
}

# Hosts-Datei aktualisieren
update_hosts() {
    print_section "Host-Konfiguration"
    print_warning "Fügen Sie folgende Einträge zu Ihrer /etc/hosts Datei hinzu:"
    echo ""
    echo "# EAI Docker Swarm Hosts"
    echo "127.0.0.1 traefik.localhost"
    echo "127.0.0.1 prometheus.localhost"
    echo "127.0.0.1 grafana.localhost"
    echo "127.0.0.1 alertmanager.localhost"
    echo "127.0.0.1 adapter-sample.localhost"
    echo "127.0.0.1 adapter-orders.localhost"
    echo "127.0.0.1 adapter-products.localhost"
    echo ""
}

# URLs und Zugangsdaten anzeigen
show_access_info() {
    print_section "Zugriffsinformationen"
    echo ""
    echo "=== INFRASTRUCTURE ==="
    echo "Traefik Dashboard:     http://traefik.localhost:8080"
    echo ""
    echo "=== MONITORING ==="
    echo "Prometheus:           http://prometheus.localhost:9090"
    echo "Grafana:              http://grafana.localhost:3000 (admin/admin)"
    echo "AlertManager:         http://alertmanager.localhost:9093"
    echo ""
    echo "=== EAI ADAPTERS ==="
    echo "Sample Adapter:       http://adapter-sample.localhost"
    echo "Orders Adapter:       http://adapter-orders.localhost"
    echo "Products Adapter:     http://adapter-products.localhost"
    echo ""
    echo "=== HEALTH CHECKS ==="
    echo "Sample Health:        http://adapter-sample.localhost/actuator/health"
    echo "Orders Health:        http://adapter-orders.localhost/actuator/health"
    echo "Products Health:      http://adapter-products.localhost/actuator/health"
    echo ""
    echo "=== METRIKEN ==="
    echo "Sample Metrics:       http://adapter-sample.localhost/actuator/prometheus"
    echo "Orders Metrics:       http://adapter-orders.localhost/actuator/prometheus"
    echo "Products Metrics:     http://adapter-products.localhost/actuator/prometheus"
    echo ""
    print_status "Alle Services sind verfügbar!"
}

# Infrastructure Stack entfernen
cleanup_infrastructure() {
    print_status "Entferne Infrastructure Stack..."
    docker stack rm infrastructure-stack
    sleep 15
    print_status "Infrastructure Stack entfernt"
}

# Monitoring Stack entfernen
cleanup_monitoring() {
    print_status "Entferne Monitoring Stack..."
    docker stack rm monitoring-stack
    sleep 15
    print_status "Monitoring Stack entfernt"
}

# EAI Stack entfernen
cleanup_eai() {
    print_status "Entferne EAI Stack..."
    docker stack rm eai-stack
    sleep 15
    print_status "EAI Stack entfernt"
}

# Vollständige Bereinigung
cleanup_all() {
    print_section "Vollständige Bereinigung..."
    cleanup_eai
    cleanup_monitoring
    cleanup_infrastructure
    
    # Netzwerke entfernen
    if docker network ls | grep -q "eai-network"; then
        docker network rm eai-network || true
    fi
    if docker network ls | grep -q "monitoring-network"; then
        docker network rm monitoring-network || true
    fi
    
    # Volumes entfernen (optional)
    if [ "${REMOVE_VOLUMES:-false}" = "true" ]; then
        print_warning "Entferne Volumes..."
        docker volume prune -f
    fi
    
    print_status "Bereinigung abgeschlossen"
}

# Service-Logs anzeigen
show_logs() {
    local service=$1
    local stack=$2
    
    if [ -z "$service" ] || [ -z "$stack" ]; then
        print_error "Usage: $0 logs <service> <stack>"
        print_status "Verfügbare Services:"
        echo "  infrastructure-stack: traefik"
        echo "  monitoring-stack: prometheus, grafana, alertmanager, node-exporter"
        echo "  eai-stack: eai-adapter-sample, eai-adapter-orders, eai-adapter-products, redis, config-db"
        exit 1
    fi
    
    print_status "Zeige Logs für ${stack}_${service}..."
    docker service logs -f ${stack}_${service}
}

# Service skalieren
scale_service() {
    local service=$1
    local replicas=$2
    local stack=$3
    
    if [ -z "$service" ] || [ -z "$replicas" ] || [ -z "$stack" ]; then
        print_error "Usage: $0 scale <service> <replicas> <stack>"
        exit 1
    fi
    
    print_status "Skaliere ${stack}_${service} auf ${replicas} Replicas..."
    docker service scale ${stack}_${service}=${replicas}
    print_status "Service skaliert"
}

# Rolling Update durchführen
update_service() {
    local service=$1
    local image=$2
    local stack=$3
    
    if [ -z "$service" ] || [ -z "$image" ] || [ -z "$stack" ]; then
        print_error "Usage: $0 update <service> <image> <stack>"
        exit 1
    fi
    
    print_status "Update ${stack}_${service} mit Image ${image}..."
    docker service update --image ${image} ${stack}_${service}
    print_status "Service Update gestartet"
}

# Hauptausführung
main() {
    case "${1:-deploy}" in
        "deploy")
            check_swarm
            create_networks
            create_secrets
            build_adapter_images
            deploy_infrastructure_stack
            deploy_monitoring_stack
            deploy_eai_stack
            check_services
            update_hosts
            show_access_info
            ;;
        "deploy-infrastructure")
            check_swarm
            create_networks
            deploy_infrastructure_stack
            check_services
            ;;
        "deploy-monitoring")
            check_swarm
            create_networks
            deploy_monitoring_stack
            check_services
            ;;
        "deploy-eai")
            check_swarm
            create_secrets
            build_adapter_images
            deploy_eai_stack
            check_services
            ;;
        "cleanup")
            cleanup_all
            ;;
        "cleanup-infrastructure")
            cleanup_infrastructure
            ;;
        "cleanup-monitoring")
            cleanup_monitoring
            ;;
        "cleanup-eai")
            cleanup_eai
            ;;
        "status")
            check_services
            ;;
        "logs")
            show_logs "$2" "$3"
            ;;
        "scale")
            scale_service "$2" "$3" "$4"
            ;;
        "update")
            update_service "$2" "$3" "$4"
            ;;
        "restart")
            case "$2" in
                "infrastructure")
                    cleanup_infrastructure
                    sleep 10
                    deploy_infrastructure_stack
                    ;;
                "monitoring")
                    cleanup_monitoring
                    sleep 10
                    deploy_monitoring_stack
                    ;;
                "eai")
                    cleanup_eai
                    sleep 10
                    deploy_eai_stack
                    ;;
                "all")
                    cleanup_all
                    sleep 10
                    main deploy
                    ;;
                *)
                    print_error "Usage: $0 restart {infrastructure|monitoring|eai|all}"
                    exit 1
                    ;;
            esac
            ;;
        "info")
            show_access_info
            ;;
        *)
            echo "Usage: $0 {deploy|deploy-infrastructure|deploy-monitoring|deploy-eai|cleanup|status|logs|scale|update|restart|info}"
            echo ""
            echo "Commands:"
            echo "  deploy                 - Deploy all three stacks (infrastructure, monitoring, eai)"
            echo "  deploy-infrastructure  - Deploy only infrastructure stack (Traefik)"
            echo "  deploy-monitoring      - Deploy only monitoring stack (Prometheus, Grafana, etc.)"
            echo "  deploy-eai            - Deploy only EAI stack (Adapters, Redis, DB)"
            echo "  cleanup               - Remove all stacks and networks"
            echo "  cleanup-infrastructure - Remove only infrastructure stack"
            echo "  cleanup-monitoring    - Remove only monitoring stack"
            echo "  cleanup-eai           - Remove only EAI stack"
            echo "  status                - Show service status"
            echo "  logs <service> <stack> - Show service logs"
            echo "  scale <service> <replicas> <stack> - Scale service"
            echo "  update <service> <image> <stack> - Update service image"
            echo "  restart {infrastructure|monitoring|eai|all} - Restart stack(s)"
            echo "  info                  - Show access information"
            echo ""
            echo "Examples:"
            echo "  $0 deploy"
            echo "  $0 deploy-infrastructure"
            echo "  $0 logs traefik infrastructure-stack"
            echo "  $0 logs prometheus monitoring-stack"
            echo "  $0 scale eai-adapter-sample 3 eai-stack"
            echo "  $0 restart infrastructure"
            exit 1
            ;;
    esac
}

# Script ausführen
main "$@"
