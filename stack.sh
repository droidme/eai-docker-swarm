#!/bin/bash

# EAI Docker Swarm Stack Management
# Simplified deployment script for 3-stack stateless EAI architecture

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Functions
print_header() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                    EAI Docker Swarm Manager                   ║"
    echo "║                 Stateless 3-Stack Architecture                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check Docker Swarm
check_swarm() {
    if ! docker info | grep -q "Swarm: active"; then
        print_warning "Docker Swarm not active. Initializing..."
        docker swarm init > /dev/null 2>&1
        print_status "Docker Swarm initialized"
    fi
}

# Create networks
create_networks() {
    local networks=("eai-network" "monitoring-network")
    for network in "${networks[@]}"; do
        if ! docker network ls | grep -q "$network"; then
            docker network create --driver overlay --attachable "$network" > /dev/null 2>&1
            print_status "Created network: $network"
        fi
    done
}

# Deploy stack
deploy_stack() {
    local stack_name=$1
    local stack_file="${stack_name}-stack.yml"
    
    if [ ! -f "$stack_file" ]; then
        print_error "Stack file not found: $stack_file"
        return 1
    fi
    
    print_info "Deploying $stack_name stack..."
    docker stack deploy -c "$stack_file" "$stack_name-stack" > /dev/null 2>&1
    print_status "$stack_name stack deployed"
}

# Wait for service
wait_for_service() {
    local service_url=$1
    local service_name=$2
    local max_retries=${3:-20}
    
    print_info "Waiting for $service_name..."
    local retries=0
    while ! curl -s "$service_url" > /dev/null 2>&1; do
        retries=$((retries + 1))
        if [ $retries -gt $max_retries ]; then
            print_warning "$service_name not available after $(($max_retries * 10)) seconds"
            return 1
        fi
        sleep 10
    done
    print_status "$service_name is ready"
}

# Show comprehensive status
show_status() {
    print_header
    
    echo -e "${CYAN}DOCKER SWARM STATUS${NC}"
    if docker info | grep -q "Swarm: active"; then
        echo -e "${GREEN}✓ Swarm Active${NC}"
        echo "  Manager: $(docker info | grep "Node Address" | cut -d: -f2 | xargs)"
        echo "  Nodes: $(docker node ls --format "table {{.Hostname}}\t{{.Status}}\t{{.Availability}}\t{{.ManagerStatus}}" | tail -n +2 | wc -l)"
    else
        echo -e "${RED}✗ Swarm Inactive${NC}"
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}STACK STATUS${NC}"
    
    # Check each stack
    local stacks=("infrastructure" "monitoring" "eai")
    for stack in "${stacks[@]}"; do
        if docker stack ls --format "{{.Name}}" | grep -q "${stack}-stack"; then
            local services=$(docker stack services "${stack}-stack" --format "{{.Name}}" | wc -l)
            local running=$(docker stack services "${stack}-stack" --format "{{.Replicas}}" | grep -o "^[0-9]*" | awk '{s+=$1} END {print s}')
            echo -e "${GREEN}✓ $(echo ${stack} | sed 's/./\U&/') Stack${NC} ($services services, $running replicas)"
            
            # Show service details
            docker stack services "${stack}-stack" --format "  {{.Name}}: {{.Replicas}}" 2>/dev/null | sed 's/.*_/  /'
        else
            echo -e "${RED}✗ $(echo ${stack} | sed 's/./\U&/') Stack${NC} (not deployed)"
        fi
    done
    
    echo ""
    echo -e "${CYAN}NETWORK STATUS${NC}"
    local networks=("eai-network" "monitoring-network")
    for network in "${networks[@]}"; do
        if docker network ls | grep -q "$network"; then
            local containers=$(docker network inspect "$network" --format "{{len .Containers}}" 2>/dev/null || echo "0")
            echo -e "${GREEN}✓ $network${NC} ($containers containers)"
        else
            echo -e "${RED}✗ $network${NC} (not created)"
        fi
    done
    
    echo ""
    echo -e "${CYAN}SERVICE ENDPOINTS${NC}"
    
    # Check service availability
    local endpoints=(
        "http://traefik.localhost:8080|Traefik Dashboard"
        "http://portainer.localhost|Portainer"
        "http://prometheus.localhost:9090|Prometheus"
        "http://grafana.localhost:3000|Grafana"
        "http://adapter-sample.localhost/actuator/health|Sample Adapter"
        "http://adapter-orders.localhost/actuator/health|Orders Adapter"
        "http://adapter-products.localhost/actuator/health|Products Adapter"
    )
    
    for endpoint in "${endpoints[@]}"; do
        local url=$(echo "$endpoint" | cut -d'|' -f1)
        local name=$(echo "$endpoint" | cut -d'|' -f2)
        
        if curl -s "$url" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ $name${NC}: $url"
        else
            echo -e "${RED}✗ $name${NC}: $url (not available)"
        fi
    done
    
    echo ""
    echo -e "${CYAN}RESOURCE USAGE${NC}"
    
    # Docker system info
    local containers=$(docker ps --format "table {{.Names}}" | tail -n +2 | wc -l)
    local images=$(docker images --format "table {{.Repository}}" | tail -n +2 | wc -l)
    local volumes=$(docker volume ls --format "table {{.Name}}" | tail -n +2 | wc -l)
    
    echo "  Containers: $containers running"
    echo "  Images: $images total"
    echo "  Volumes: $volumes total"
    
    # System resources
    if command -v free > /dev/null 2>&1; then
        local memory=$(free -h | awk '/^Mem:/ {print $3 "/" $2}')
        echo "  Memory: $memory"
    fi
    
    if command -v df > /dev/null 2>&1; then
        local disk=$(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')
        echo "  Disk: $disk"
    fi
}

# Show service logs
show_logs() {
    local service=$1
    local stack=$2
    
    if [ -z "$service" ] || [ -z "$stack" ]; then
        print_error "Usage: $0 logs <service> <stack>"
        echo ""
        echo "Available services:"
        echo "  infrastructure: traefik"
        echo "  monitoring: prometheus, grafana, alertmanager, node-exporter"
        echo "  eai: eai-adapter-sample, eai-adapter-orders, eai-adapter-products, redis"
        return 1
    fi
    
    local full_service="${stack}-stack_${service}"
    print_info "Showing logs for $full_service..."
    docker service logs -f "$full_service"
}

# Scale service
scale_service() {
    local service=$1
    local replicas=$2
    local stack=$3
    
    if [ -z "$service" ] || [ -z "$replicas" ] || [ -z "$stack" ]; then
        print_error "Usage: $0 scale <service> <replicas> <stack>"
        return 1
    fi
    
    local full_service="${stack}-stack_${service}"
    print_info "Scaling $full_service to $replicas replicas..."
    docker service scale "${full_service}=${replicas}"
    print_status "Service scaled successfully"
}

# Update service
update_service() {
    local service=$1
    local image=$2
    local stack=$3
    
    if [ -z "$service" ] || [ -z "$image" ] || [ -z "$stack" ]; then
        print_error "Usage: $0 update <service> <image> <stack>"
        return 1
    fi
    
    local full_service="${stack}-stack_${service}"
    print_info "Updating $full_service with image $image..."
    docker service update --image "$image" "$full_service"
    print_status "Service update initiated"
}

# Deploy all stacks
deploy_all() {
    print_header
    print_info "Deploying complete EAI environment..."
    
    check_swarm
    create_networks
    
    # Deploy in order
    deploy_stack "infrastructure"
    sleep 15
    wait_for_service "http://localhost:8080/api/rawdata" "Traefik"
    
    deploy_stack "monitoring"
    sleep 30
    wait_for_service "http://localhost:9090/-/healthy" "Prometheus"
    
    deploy_stack "eai"
    sleep 20
    
    print_status "All stacks deployed successfully!"
    echo ""
    show_access_info
}

# Remove stacks
cleanup() {
    local target=${1:-all}
    
    case $target in
        all)
            print_info "Removing all stacks..."
            docker stack rm eai-stack monitoring-stack infrastructure-stack 2>/dev/null || true
            ;;
        infrastructure|monitoring|eai)
            print_info "Removing ${target} stack..."
            docker stack rm "${target}-stack" 2>/dev/null || true
            ;;
        *)
            print_error "Usage: $0 cleanup [all|infrastructure|monitoring|eai]"
            return 1
            ;;
    esac
    
    sleep 10
    print_status "Cleanup completed"
}

# Show access information
show_access_info() {
    echo -e "${CYAN}ACCESS INFORMATION${NC}"
    echo ""
    echo -e "${YELLOW}Infrastructure:${NC}"
    echo "  Traefik Dashboard: http://traefik.localhost:8080"
    echo "  Portainer:         http://portainer.localhost"
    echo ""
    echo -e "${YELLOW}Monitoring:${NC}"
    echo "  Prometheus:        http://prometheus.localhost:9090"
    echo "  Grafana:           http://grafana.localhost:3000 (admin/admin)"
    echo "  AlertManager:      http://alertmanager.localhost:9093"
    echo ""
    echo -e "${YELLOW}EAI Adapters:${NC}"
    echo "  Sample Adapter:    http://adapter-sample.localhost"
    echo "  Orders Adapter:    http://adapter-orders.localhost"
    echo "  Products Adapter:  http://adapter-products.localhost"
    echo ""
    echo -e "${YELLOW}Health Checks:${NC}"
    echo "  curl http://adapter-sample.localhost/actuator/health"
    echo "  curl http://adapter-orders.localhost/actuator/health"
    echo "  curl http://adapter-products.localhost/actuator/health"
    echo ""
    echo -e "${YELLOW}Add to /etc/hosts:${NC}"
    echo "  127.0.0.1 traefik.localhost portainer.localhost prometheus.localhost grafana.localhost"
    echo "  127.0.0.1 alertmanager.localhost adapter-sample.localhost"
    echo "  127.0.0.1 adapter-orders.localhost adapter-products.localhost"
}

# Show help
show_help() {
    print_header
    echo "USAGE:"
    echo "  $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "COMMANDS:"
    echo "  status                              Show comprehensive system status (default)"
    echo "  deploy [all|infrastructure|monitoring|eai]  Deploy stack(s)"
    echo "  cleanup [all|infrastructure|monitoring|eai] Remove stack(s)"
    echo "  logs <service> <stack>              Show service logs"
    echo "  scale <service> <replicas> <stack>  Scale service"
    echo "  update <service> <image> <stack>    Update service image"
    echo "  restart <stack>                     Restart stack"
    echo "  info                               Show access information"
    echo "  help                               Show this help"
    echo ""
    echo "EXAMPLES:"
    echo "  $0                                  # Show status"
    echo "  $0 deploy                          # Deploy all stacks"
    echo "  $0 deploy monitoring               # Deploy only monitoring"
    echo "  $0 logs traefik infrastructure     # Show traefik logs"
    echo "  $0 scale eai-adapter-sample 3 eai  # Scale sample adapter"
    echo "  $0 cleanup eai                     # Remove EAI stack"
    echo ""
    echo "STACKS:"
    echo "  infrastructure: Traefik reverse proxy"
    echo "  monitoring:     Prometheus, Grafana, AlertManager"
    echo "  eai:           Stateless EAI adapters + Redis"
}

# Restart stack
restart_stack() {
    local stack=$1
    
    if [ -z "$stack" ]; then
        print_error "Usage: $0 restart <stack>"
        echo "Available stacks: infrastructure, monitoring, eai, all"
        return 1
    fi
    
    if [ "$stack" = "all" ]; then
        cleanup all
        sleep 10
        deploy_all
    else
        cleanup "$stack"
        sleep 5
        deploy_stack "$stack"
        print_status "$stack stack restarted"
    fi
}

# Main execution
main() {
    case "${1:-status}" in
        status|"")
            show_status
            ;;
        deploy)
            case "${2:-all}" in
                all)
                    deploy_all
                    ;;
                infrastructure|monitoring|eai)
                    check_swarm
                    create_networks
                    deploy_stack "$2"
                    print_status "$2 stack deployed"
                    ;;
                *)
                    print_error "Invalid stack: $2"
                    echo "Available stacks: all, infrastructure, monitoring, eai"
                    exit 1
                    ;;
            esac
            ;;
        cleanup)
            cleanup "$2"
            ;;
        logs)
            show_logs "$2" "$3"
            ;;
        scale)
            scale_service "$2" "$3" "$4"
            ;;
        update)
            update_service "$2" "$3" "$4"
            ;;
        restart)
            restart_stack "$2"
            ;;
        info)
            show_access_info
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
