# EAI Docker Swarm 3-Stack Architektur

Eine modulare Docker Swarm Umgebung für Enterprise Application Integration (EAI) mit getrennten Stacks für Infrastructure, Monitoring und EAI-Services.

## 🏗️ 3-Stack Architektur

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Docker Swarm Cluster                             │
├───────────────────┬─────────────────────────┬─────────────────────────────┤
│ Infrastructure    │    Monitoring Stack     │         EAI Stack           │
│     Stack         │                         │                             │
│ ┌───────────────┐ │ ┌─────────────────────┐ │ ┌─────────────────────────┐ │
│ │    Traefik    │ │ │     Prometheus      │ │ │   EAI Adapter Sample    │ │
│ │ (Reverse      │◄┼─┤   (Metrics/Alerts) │◄┼─┤   (Spring Boot/Camel)   │ │
│ │  Proxy)       │ │ └─────────────────────┘ │ └─────────────────────────┘ │
│ └───────────────┘ │ ┌─────────────────────┐ │ ┌─────────────────────────┐ │
│                   │ │      Grafana        │ │ │   EAI Adapter Orders    │ │
│                   │ │   (Dashboards)      │ │ │   (Spring Boot/Camel)   │ │
│                   │ └─────────────────────┘ │ └─────────────────────────┘ │
│                   │ ┌─────────────────────┐ │ ┌─────────────────────────┐ │
│                   │ │   AlertManager      │ │ │   EAI Adapter Products  │ │
│                   │ │  (Notifications)    │ │ │   (Spring Boot/Camel)   │ │
│                   │ └─────────────────────┘ │ └─────────────────────────┘ │
│                   │ ┌─────────────────────┐ │ ┌─────────────────────────┐ │
│                   │ │   Node Exporter     │ │ │        Redis            │ │
│                   │ │  (System Metrics)   │ │ │   (Message Queue)       │ │
│                   │ └─────────────────────┘ │ └─────────────────────────┘ │
│                   │                         │ ┌─────────────────────────┐ │
│                   │                         │ │      PostgreSQL         │ │
│                   │                         │ │   (Config Database)     │ │
│                   │                         │ └─────────────────────────┘ │
└───────────────────┴─────────────────────────┴─────────────────────────────┘
```

## 🚀 3-Stack Vorteile

### **Infrastructure Independence**
- **Traefik** als zentraler Entry Point in eigenem Stack
- Unabhängige Updates ohne Auswirkung auf andere Services
- Bessere SSL/TLS Verwaltung und Zertifikat-Handling

### **Monitoring Isolation**
- **Dedizierter Monitoring Stack** für alle Observability Tools
- Unabhängige Skalierung der Monitoring-Infrastruktur
- Keine Beeinträchtigung bei EAI-Updates

### **EAI Business Logic Separation**
- **Reine Business-Services** ohne Infrastructure-Abhängigkeiten
- Unabhängige Entwicklungs- und Deployment-Zyklen
- Saubere Trennung von Infrastruktur und Geschäftslogik

### **Enhanced Operations**
- **Role-Based Stack Management** (Infrastructure-, Monitoring-, Dev-Teams)
- **Independent Scaling** pro Stack
- **Simplified Troubleshooting** durch klare Verantwortlichkeiten

## 📋 Stack-Definitionen

### Infrastructure Stack (`infrastructure-stack.yml`)
- **Traefik**: Reverse Proxy, Load Balancer, SSL Termination
- **Service Discovery**: Automatische Erkennung aller Services
- **Metrics Export**: Traefik-Metriken für Prometheus

### Monitoring Stack (`monitoring-stack.yml`)
- **Prometheus**: Metriken-Sammlung und Alerting Rules
- **Grafana**: Dashboards und Visualisierung
- **AlertManager**: Alert-Routing und Benachrichtigungen
- **Node Exporter**: System-Metriken aller Nodes

### EAI Stack (`eai-stack.yml`)
- **EAI Adapter Sample**: Beispiel-Integration (Replicas: 2)
- **EAI Adapter Orders**: Bestellungs-Integration (Replicas: 1)
- **EAI Adapter Products**: Produkt-Integration (Replicas: 1)
- **Redis**: Message Queue und Cache
- **PostgreSQL**: Konfigurationsdatenbank

## 🛠️ Deployment

### Komplettes System deployen
```bash
./deploy-multistack.sh deploy
```

### Einzelne Stacks deployen
```bash
# Infrastructure Stack (Traefik)
./deploy-multistack.sh deploy-infrastructure

# Monitoring Stack (Prometheus, Grafana, etc.)
./deploy-multistack.sh deploy-monitoring

# EAI Stack (Business Services)
./deploy-multistack.sh deploy-eai
```

### Stack-spezifische Operationen
```bash
# Service skalieren
./deploy-multistack.sh scale eai-adapter-sample 3 eai-stack

# Service-Logs anzeigen
./deploy-multistack.sh logs traefik infrastructure-stack
./deploy-multistack.sh logs prometheus monitoring-stack

# Rolling Update
./deploy-multistack.sh update eai-adapter-sample eai-adapter-sample:v2 eai-stack

# Stack neu starten
./deploy-multistack.sh restart infrastructure
./deploy-multistack.sh restart monitoring
./deploy-multistack.sh restart eai
./deploy-multistack.sh restart all
```

## 🌐 Service-Zugriff

### Infrastructure Stack
| Service | URL | Beschreibung |
|---------|-----|--------------|
| Traefik Dashboard | http://traefik.localhost:8080 | Reverse Proxy Management |

### Monitoring Stack
| Service | URL | Beschreibung |
|---------|-----|--------------|
| Prometheus | http://prometheus.localhost:9090 | Metriken & Alerts |
| Grafana | http://grafana.localhost:3000 | Dashboards (admin/admin) |
| AlertManager | http://alertmanager.localhost:9093 | Alert-Management |

### EAI Stack
| Service | URL | Beschreibung |
|---------|-----|--------------|
| Sample Adapter | http://adapter-sample.localhost | Beispiel EAI Adapter |
| Orders Adapter | http://adapter-orders.localhost | Bestellungs-Adapter |
| Products Adapter | http://adapter-products.localhost | Produkt-Adapter |

## 📊 Cross-Stack Monitoring

### Service Discovery
Prometheus erkennt automatisch Services aus allen Stacks:
```yaml
# Infrastructure Stack Services
- job_name: 'infrastructure-stack'
  dockerswarm_sd_configs:
    - role: tasks
  relabel_configs:
    - source_labels: [__meta_dockerswarm_service_label_infrastructure_stack]
      regex: true
      action: keep

# EAI Stack Services  
- job_name: 'eai-adapters'
  dockerswarm_sd_configs:
    - role: tasks
  relabel_configs:
    - source_labels: [__meta_dockerswarm_service_label_prometheus_scrape]
      regex: true
      action: keep
```

### Verfügbare Metriken

**Infrastructure Metriken:**
- `traefik_service_requests_total` - HTTP Requests pro Service
- `traefik_service_request_duration_seconds` - Response Times
- `traefik_backend_requests_total` - Backend Load

**EAI Adapter Metriken:**
- `eai_messages_processed_total` - Verarbeitete Nachrichten
- `eai_routes_active` - Aktive Camel Routes
- `CamelExchangesTotal` - Camel Exchange Statistiken
- `CamelExchangesFailed` - Fehlgeschlagene Exchanges

**System Metriken:**
- `node_cpu_seconds_total` - CPU Usage
- `node_memory_MemAvailable_bytes` - Available Memory
- `node_filesystem_avail_bytes` - Disk Space

## 🔧 Stack-Management

### Infrastructure Operations
```bash
# Traefik SSL Zertifikate erneuern
./deploy-multistack.sh restart infrastructure

# Traefik Konfiguration prüfen
curl http://traefik.localhost:8080/api/rawdata

# Load Balancer Status
curl http://traefik.localhost:8080/api/http/services
```

### Monitoring Operations
```bash
# Prometheus Targets prüfen
curl http://prometheus.localhost:9090/api/v1/targets

# Grafana Datasource testen
curl http://grafana.localhost:3000/api/datasources/proxy/1/api/v1/query?query=up

# AlertManager Alerts anzeigen
curl http://alertmanager.localhost:9093/api/v1/alerts
```

### EAI Operations
```bash
# Adapter Health Checks
curl http://adapter-sample.localhost/actuator/health
curl http://adapter-orders.localhost/actuator/health
curl http://adapter-products.localhost/actuator/health

# Camel Routes Status
curl http://adapter-sample.localhost/actuator/camel/routes

# Database Connection Test
./deploy-multistack.sh logs config-db eai-stack
```

## 🛡️ Sicherheit & Netzwerke

### Network Isolation
```yaml
# Cross-Stack Networks
networks:
  eai-network:          # Shared: EAI ↔ Infrastructure
    external: true
  monitoring-network:   # Shared: Monitoring ↔ Infrastructure  
    external: true
  traefik-network:      # Internal: Infrastructure only
    driver: overlay
```

### Security Features
- **Network Segmentation** zwischen Stacks
- **Docker Secrets** für sensitive Daten
- **Health Checks** mit Timeouts
- **Resource Limits** pro Service
- **SSL Termination** im Infrastructure Stack

## 🚀 Development Workflow

### Team-basierte Entwicklung
```bash
# Infrastructure Team
./deploy-multistack.sh deploy-infrastructure
./deploy-multistack.sh logs traefik infrastructure-stack

# Monitoring Team  
./deploy-multistack.sh deploy-monitoring
./deploy-multistack.sh logs prometheus monitoring-stack

# EAI Development Team
./deploy-multistack.sh deploy-eai
./deploy-multistack.sh scale eai-adapter-sample 3 eai-stack
```

### Neuen EAI Adapter hinzufügen
1. **Adapter entwickeln** in `eai-adapters/my-adapter/`
2. **Service in eai-stack.yml definieren:**
```yaml
eai-adapter-myservice:
  image: eai-adapter-myservice:latest
  deploy:
    labels:
      - traefik.enable=true
      - traefik.http.routers.eai-adapter-myservice.rule=Host(`adapter-myservice.localhost`)
      - prometheus.scrape=true
      - eai.adapter.type=myservice
```
3. **EAI Stack neu deployen:**
```bash
./deploy-multistack.sh restart eai
```

## 🔍 Troubleshooting

### Stack-spezifische Probleme

**Infrastructure Stack:**
```bash
# Traefik Service Discovery prüfen
./deploy-multistack.sh logs traefik infrastructure-stack

# Port-Konflikte prüfen
netstat -tulpn | grep -E ':(80|443|8080)'
```

**Monitoring Stack:**
```bash
# Prometheus Service Discovery
curl http://prometheus.localhost:9090/api/v1/targets

# Grafana Datasource Status
./deploy-multistack.sh logs grafana monitoring-stack
```

**EAI Stack:**
```bash
# Adapter-spezifische Probleme
./deploy-multistack.sh logs eai-adapter-sample eai-stack

# Database Connectivity
./deploy-multistack.sh logs config-db eai-stack
```

### Cross-Stack Issues
```bash
# Netzwerk-Konnektivität testen
docker exec $(docker ps -q -f name=prometheus) ping traefik
docker exec $(docker ps -q -f name=traefik) ping eai-adapter-sample

# Service Labels prüfen
docker service inspect infrastructure-stack_traefik --format '{{.Spec.Labels}}'
```

## 📚 Dateien-Übersicht

```
eai-docker-swarm/
├── infrastructure-stack.yml      # Traefik Infrastructure
├── monitoring-stack.yml          # Monitoring Services  
├── eai-stack.yml                 # EAI Business Services
├── deploy-multistack.sh          # 3-Stack Deployment Script
├── prometheus/
│   ├── prometheus.yml            # Cross-Stack Service Discovery
│   └── alerts/
│       └── eai-alerts.yml        # Alert Rules für alle Stacks
├── grafana/
│   ├── provisioning/             # Auto-Provisioning
│   └── dashboards/               # 3-Stack Dashboards
├── alertmanager/
│   └── alertmanager.yml          # Alert Routing
├── database/
│   └── init/
│       └── 01-init-schema.sql    # PostgreSQL Schema
├── configs/
│   ├── eai-global-config.yml     # Globale EAI Konfiguration
│   └── logback-spring.xml        # Logging Konfiguration
└── eai-adapters/                 # Adapter Source Code
    ├── sample/
    ├── orders/
    └── products/
```

## 🔄 Migration von 2-Stack

Falls Sie von der 2-Stack Version migrieren:

### 1. Backup erstellen
```bash
cp monitoring-stack.yml monitoring-stack.yml.backup
```

### 2. Infrastructure Stack extrahieren
- Traefik wurde aus monitoring-stack.yml entfernt
- Neuer infrastructure-stack.yml wurde erstellt

### 3. Deployment anpassen
```bash
# Alt: 2 Stacks
./deploy-multistack.sh deploy-monitoring
./deploy-multistack.sh deploy-eai

# Neu: 3 Stacks  
./deploy-multistack.sh deploy-infrastructure
./deploy-multistack.sh deploy-monitoring
./deploy-multistack.sh deploy-eai

# Oder alles auf einmal
./deploy-multistack.sh deploy
```

## 🤝 Team-Verantwortlichkeiten

### Infrastructure Team
- **Traefik Konfiguration** und SSL Management
- **Network Policies** und Security
- **Service Discovery** Regeln

### Monitoring Team  
- **Prometheus** Konfiguration und Rules
- **Grafana** Dashboards und Alerting
- **AlertManager** Routing und Escalation

### EAI Development Team
- **Business Logic** in EAI Adapters
- **Camel Routes** und Integration Patterns
- **Database Schema** und Configurations

## 📄 Vorteile der 3-Stack Architektur

### ✅ **Operational Excellence**
- Klare Verantwortlichkeiten pro Stack
- Unabhängige Update-Zyklen
- Bessere Isolation bei Problemen

### ✅ **Scalability**
- Infrastructure kann unabhängig skaliert werden
- Monitoring Resources nach Bedarf
- EAI Services basierend auf Business Load

### ✅ **Security** 
- Network Segmentation zwischen Layers
- Minimale Cross-Stack Dependencies
- Principle of Least Privilege

### ✅ **Maintainability**
- Kleinere, fokussierte Stack-Definitionen
- Team-spezifische Deployment-Strategien
- Simplified Debugging und Monitoring

---

**Version**: 3.0.0 - 3-Stack Architecture  
**Lizenz**: MIT
