# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Enterprise Application Integration (EAI) platform built on Docker Swarm with a stateless 3-stack architecture:

- **Infrastructure Stack**: Traefik reverse proxy for service discovery and load balancing
- **Monitoring Stack**: Prometheus, Grafana, AlertManager, and Node Exporter for observability
- **EAI Stack**: Stateless Spring Boot adapters with Apache Camel integration and Redis cache

The platform emphasizes environment-driven configuration (no config files), horizontal scalability, and production readiness.

## Essential Commands

### Stack Management
```bash
./stack.sh                    # Show comprehensive status (default command)
./stack.sh deploy            # Deploy all stacks
./stack.sh deploy monitoring # Deploy specific stack
./stack.sh cleanup           # Remove all stacks
./stack.sh restart eai       # Restart specific stack
```

### Service Operations
```bash
./stack.sh scale eai-adapter-sample 3 eai    # Scale service replicas
./stack.sh logs traefik infrastructure       # View service logs
./stack.sh update eai-adapter-sample my-app:v2 eai  # Update service image
```

### Development Commands
```bash
# Build Java adapters (in eai-adapters/orders/ or eai-adapters/sample/)
mvn clean package

# Build Docker images
docker build -t eai-adapter-orders:latest .
docker build -t eai-adapter-sample:latest .

# Test health endpoints
curl http://adapter-sample.localhost/actuator/health
curl http://adapter-orders.localhost/actuator/health
```

## Architecture

### Three-Stack Design
1. **infrastructure-stack.yml**: Contains Traefik reverse proxy
2. **monitoring-stack.yml**: Contains Prometheus, Grafana, AlertManager, Node Exporter
3. **eai-stack.yml**: Contains EAI adapters and Redis cache

### Key Design Principles
- **Stateless Architecture**: All configuration via environment variables
- **Service Discovery**: Automatic via Traefik labels
- **Health Checks**: Built-in health monitoring with automatic restarts
- **Prometheus Integration**: All services expose /actuator/prometheus endpoints

### EAI Adapters
Spring Boot applications using Apache Camel for integration patterns:
- Built with Maven (Java 17, Spring Boot 3.2.0, Camel 4.2.0)
- Expose health, metrics, and Camel route endpoints via Spring Actuator
- Environment-driven configuration (no application.properties files in production)
- Example adapters: sample (port 8080), orders (port 8080), products (port 8080)

## Development Workflow

### Adding New Adapters
1. Create new Maven project in `eai-adapters/` directory following existing structure
2. Add service definition to `eai-stack.yml` with proper environment variables
3. Include Traefik labels for service discovery:
   ```yaml
   labels:
     - traefik.enable=true
     - traefik.http.routers.your-adapter.rule=Host(`adapter-name.localhost`)
     - prometheus.scrape=true
     - prometheus.path=/actuator/prometheus
   ```

### Environment Configuration
All configuration is handled via environment variables in the stack files:
- `EAI_POLLING_INTERVAL`: Message polling interval (ms)
- `EAI_BATCH_SIZE`: Batch processing size
- `EAI_RETRY_ATTEMPTS`: Number of retry attempts
- `EAI_TIMEOUT`: Operation timeout (ms)
- Service-specific variables: `EAI_ORDERS_*`, `EAI_PRODUCTS_*`, etc.

### Service Access URLs
- Traefik Dashboard: http://traefik.localhost:8080
- Portainer: http://portainer.localhost (setup required on first visit)
- Prometheus: http://prometheus.localhost:9090
- Grafana: http://grafana.localhost:3000 (admin/admin)
- Adapters: http://adapter-{name}.localhost

**Note**: Portainer requires initial setup on first visit. Create an admin user with strong credentials during the setup wizard.

### Monitoring and Observability
- All services automatically discovered by Prometheus via Docker Swarm labels
- Pre-configured Grafana dashboards in `grafana/dashboards/`
- Alert rules defined in `prometheus/alerts/eai-alerts.yml`
- Key metrics: `eai_messages_processed_total`, `CamelExchangesTotal`, JVM metrics

## Technology Stack

### Core Technologies
- **Docker Swarm**: Container orchestration
- **Spring Boot 3.2.0**: Application framework
- **Apache Camel 4.2.0**: Integration patterns
- **Traefik**: Reverse proxy and load balancer
- **Prometheus/Grafana**: Monitoring and visualization
- **Redis**: Caching and message queuing

### Build Tools
- **Maven**: Java project management and builds
- **Docker**: Container builds and deployments
- **Bash**: Management scripts and automation

## File Structure

```
├── stack.sh                    # Main management script
├── infrastructure-stack.yml    # Traefik configuration
├── monitoring-stack.yml        # Monitoring services
├── eai-stack.yml              # EAI adapters and Redis
├── prometheus/                 # Prometheus config and alerts
├── grafana/                   # Dashboards and provisioning
├── eai-adapters/              # Spring Boot adapter source code
│   ├── sample/                # Sample adapter with basic routes
│   └── orders/                # Orders processing adapter
└── traefik/                   # Traefik configuration files
```

## Testing and Validation

### Health Checks
All services include health check endpoints accessible via:
```bash
curl http://adapter-name.localhost/actuator/health
```

### Service Validation
```bash
# Check all service status
./stack.sh

# View specific service logs
./stack.sh logs service-name stack-name

# Check Prometheus targets
curl http://prometheus.localhost:9090/api/v1/targets
```

## Common Operations

### Scaling Services
```bash
./stack.sh scale eai-adapter-sample 3 eai
```

### Updating Service Images
```bash
./stack.sh update eai-adapter-orders new-image:tag eai
```

### Configuration Updates
Runtime configuration updates without restarts:
```bash
docker service update \
  --env-add EAI_POLLING_INTERVAL=60000 \
  eai-stack_eai-adapter-orders
```

### Troubleshooting
- Check overall status: `./stack.sh`
- View logs: `./stack.sh logs service-name stack-name`
- Check Docker Swarm: `docker node ls`
- Verify networks: `docker network ls`
