# EAI Docker Swarm Architecture

```mermaid
graph TB
    %% External
    Internet[🌐 Internet/Users]
    
    %% Infrastructure Stack
    subgraph Infrastructure["🏗️ Infrastructure Stack"]
        Traefik[🔀 Traefik<br/>Reverse Proxy<br/>Load Balancer<br/>:8080]
        Portainer[📋 Portainer<br/>Management UI]
    end
    
    %% EAI Stack
    subgraph EAI["⚙️ EAI Stack"]
        subgraph Adapters["Spring Boot Adapters"]
            AdapterSample[📦 Sample Adapter<br/>Spring Boot + Camel<br/>:8080]
            AdapterOrders[🛒 Orders Adapter<br/>Spring Boot + Camel<br/>:8080]
            AdapterProducts[📋 Products Adapter<br/>Spring Boot + Camel<br/>:8080]
        end
        Redis[(🗄️ Redis<br/>Cache & Queue<br/>:6379)]
    end
    
    %% Monitoring Stack
    subgraph Monitoring["📊 Monitoring Stack"]
        Prometheus[📈 Prometheus<br/>Metrics Collection<br/>:9090]
        Grafana[📊 Grafana<br/>Dashboards<br/>:3000]
        AlertManager[🚨 AlertManager<br/>Alerting<br/>:9093]
        NodeExporter[🖥️ Node Exporter<br/>System Metrics<br/>:9100]
    end
    
    %% Docker Swarm Infrastructure
    subgraph DockerSwarm["🐳 Docker Swarm Cluster"]
        Node1[Manager Node]
        Node2[Worker Node]
        Node3[Worker Node]
    end
    
    %% Connections
    Internet --> Traefik
    
    %% Traffic routing
    Traefik -->|adapter-sample.localhost| AdapterSample
    Traefik -->|adapter-orders.localhost| AdapterOrders  
    Traefik -->|adapter-products.localhost| AdapterProducts
    Traefik -->|traefik.localhost:8080| Traefik
    Traefik -->|portainer.localhost| Portainer
    Traefik -->|prometheus.localhost:9090| Prometheus
    Traefik -->|grafana.localhost:3000| Grafana
    
    %% EAI Connections
    AdapterSample <--> Redis
    AdapterOrders <--> Redis
    AdapterProducts <--> Redis
    
    %% Monitoring Connections
    Prometheus -->|scrape metrics| AdapterSample
    Prometheus -->|scrape metrics| AdapterOrders
    Prometheus -->|scrape metrics| AdapterProducts
    Prometheus -->|scrape metrics| Redis
    Prometheus -->|scrape metrics| Traefik
    Prometheus -->|scrape metrics| NodeExporter
    
    Grafana -->|query metrics| Prometheus
    AlertManager -->|alerts| Prometheus
    
    %% Docker Swarm deployment
    Infrastructure -.->|deployed on| DockerSwarm
    EAI -.->|deployed on| DockerSwarm
    Monitoring -.->|deployed on| DockerSwarm
    
    %% Styling
    classDef infrastructure fill:#e1f5fe
    classDef eai fill:#f3e5f5
    classDef monitoring fill:#fff3e0
    classDef swarm fill:#e8f5e8
    
    class Infrastructure,Traefik,Portainer infrastructure
    class EAI,Adapters,AdapterSample,AdapterOrders,AdapterProducts,Redis eai
    class Monitoring,Prometheus,Grafana,AlertManager,NodeExporter monitoring
    class DockerSwarm,Node1,Node2,Node3 swarm
```

## Key Features

- **Service Discovery**: Automatic via Traefik labels
- **Load Balancing**: Traefik distributes traffic across replicas
- **Health Monitoring**: All services expose `/actuator/health` endpoints
- **Metrics Collection**: Prometheus scrapes `/actuator/prometheus` endpoints
- **Horizontal Scaling**: Stateless adapters can be scaled independently
- **Environment-driven Config**: No config files, all via environment variables

## Access URLs

- Traefik Dashboard: `http://traefik.localhost:8080`
- Portainer: `http://portainer.localhost`
- Prometheus: `http://prometheus.localhost:9090`
- Grafana: `http://grafana.localhost:3000` (admin/admin)
- Sample Adapter: `http://adapter-sample.localhost`
- Orders Adapter: `http://adapter-orders.localhost`
- Products Adapter: `http://adapter-products.localhost`
```