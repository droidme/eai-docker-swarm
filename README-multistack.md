# EAI Docker Swarm Multi-Stack Umgebung

Eine modulare Docker Swarm Umgebung für Enterprise Application Integration (EAI) mit getrennten Stacks für Monitoring und EAI-Services.

## 🏗️ Multi-Stack Architektur

```
┌─────────────────────────────────────────────────────────────────┐
│                    Docker Swarm Cluster                        │
├─────────────────────────────┬───────────────────────────────────┤
│      Monitoring Stack       │           EAI Stack               │
│  ┌─────────────────────┐   │  ┌─────────────────────────────┐   │
│  │     Traefik         │   │  │    EAI Adapter Sample       │   │
│  │  (Reverse Proxy)    │◄──┼──┤    (Spring Boot/Camel)     │   │
│  └─────────────────────┘   │  └─────────────────────────────┘   │
│  ┌─────────────────────┐   │  ┌─────────────────────────────┐   │
│  │    Prometheus       │◄──┼──┤    EAI Adapter Orders      │   │
│  │  (Metrics/Alerts)   │   │  │    (Spring Boot/Camel)     │   │
│  └─────────────────────┘   │  └─────────────────────────────┘   │
│  ┌─────────────────────┐   │  ┌─────────────────────────────┐   │
│  │     Grafana         │   │  │    EAI Adapter Products    │   │
│  │   (Dashboards)      │   │  │    (Spring Boot/Camel)     │   │
│  └─────────────────────┘   │  └─────────────────────────────┘   │
│  ┌─────────────────────┐   │  ┌─────────────────────────────┐   │
│  │   AlertManager      │   │  │         Redis               │   │
│  │   (Notifications)   │   │  │    (Message Queue)          │   │
│  └─────────────────────┘   │  └─────────────────────────────┘   │
│  ┌─────────────────────┐   │  ┌─────────────────────────────┐   │
│  │   Node Exporter     │   │  │      PostgreSQL             │   │
│  │  (System Metrics)   │   │  │    (Config Database)        │   │
│  └─────────────────────┘   │  └─────────────────────────────┘   │
└─────────────────────────────┴───────────────────────────────────┘
```

## 🚀 Multi-Stack Vorteile

### **Unabhängige Lifecycle-Verwaltung**
- Monitoring Stack kann unabhängig aktualisiert werden
- EAI Stack Deployments beeinträchtigen Monitoring nicht
- Separate Entwicklungs- und Deployment-Zyklen

### **Isolierte Ressourcenverwaltung**
- Dedizierte Netzwerke pro Stack
- Unabhängige Skalierung der Stack-Komponenten
- Bessere Ressourcen-Allokation

### **Erweiterte Sicherheit**
- Netzwerk-Isolation zwischen Stacks
- Getrennte Secret-Verwaltung
- Minimale Service-Exposition

### **Service Discovery**
- Cross-Stack Service-Erkennung
- Automatische Metriken-Sammlung
- Dynamische Load Balancer-Konfiguration

## 📋 Stack-Definitionen

### Monitoring Stack (`monitoring-stack.yml`)
- **Traefik**: Reverse Proxy und Service Discovery
- **Prometheus**: Metriken-Sammlung und Alerting Rules
- **Grafana**: Dashboards und Visualisierung
- **AlertManager**: Alert-Routing und Benachrichtigungen
- **Node Exporter**: System-Metriken

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

### Nur Monitoring Stack
```bash
./deploy-multistack.sh deploy-monitoring
```

### Nur EAI Stack
```bash
./deploy-multistack.sh deploy-eai
```

### Stack-spezifische Operationen
```bash
# Service skalieren
./deploy-multistack.sh scale eai-adapter-sample 3 eai-stack

# Service-Logs anzeigen
./deploy-multistack.sh logs prometheus monitoring-stack

# Rolling Update
./deploy-multistack.sh update eai-adapter-sample eai-adapter-sample:v2 eai-stack

# Stack neu starten
./deploy-multistack.sh restart monitoring
./deploy-multistack.sh restart eai
./deploy-multistack.sh restart all
```

## 🌐 Service-Zugriff

### Monitoring Stack
| Service | URL | Beschreibung |
|---------|-----|--------------|
| Traefik Dashboard | http://traefik.localhost:8080 | Reverse Proxy Management |
| Prometheus | http://prometheus.localhost:9090 | Metriken & Alerts |
| Grafana | http://grafana.localhost:3000 | Dashboards (admin/admin) |
| AlertManager | http://alertmanager.localhost:9093 | Alert-Management |

### EAI Stack
| Service | URL | Beschreibung |
|---------|-----|--------------|
| Sample Adapter | http://adapter-sample.localhost | Beispiel EAI Adapter |
| Orders Adapter | http://adapter-orders.localhost | Bestellungs-Adapter |
| Products Adapter | http://adapter-products.localhost | Produkt-Adapter |

## 📊 Monitoring & Observability

### Verfügbare Metriken

**EAI Adapter Metriken:**
- `eai_messages_processed_total` - Verarbeitete Nachrichten
- `eai_routes_active` - Aktive Camel Routes
- `CamelExchangesTotal` - Camel Exchange Statistiken
- `CamelExchangesFailed` - Fehlgeschlagene Exchanges
- `CamelProcessingTime` - Verarbeitungszeiten

**Infrastruktur Metriken:**
- `jvm_memory_used_bytes` - JVM Memory Usage
- `process_cpu_usage` - CPU-Auslastung
- `http_server_requests_seconds` - HTTP Request Metriken
- `tomcat_threads_busy_threads` - Thread Pool Usage

### Alert Rules
Vorkonfigurierte Alerts für:
- Service Health (EAI Adapter Down)
- Resource Usage (High Memory/CPU)
- Business Metrics (High Error Rate, No Traffic)
- Infrastructure (Traefik, Prometheus, Redis, DB Down)

## 🔧 Konfiguration

### Global Configuration
Die globale EAI-Konfiguration befindet sich in `configs/eai-global-config.yml`:

```yaml
eai:
  global:
    cluster:
      name: "eai-swarm-cluster"
      environment: "production"
    monitoring:
      enabled: true
    security:
      basic_auth:
        enabled: false
```

### Logging Configuration
Strukturiertes JSON-Logging mit `configs/logback-spring.xml`:
- Console und File Appender
- Async Logging für Performance
- Profile-spezifische Konfigurationen
- Business und Security Audit Logs

### Database Schema
Automatische Initialisierung der PostgreSQL-Datenbank:
- Adapter-Konfigurationstabellen
- Route-Definitionen
- Business-Metriken
- Indizes für Performance

## 🛡️ Sicherheit

### Docker Secrets
```bash
# Secrets werden automatisch erstellt
config_db_password  # PostgreSQL Passwort
```

### Network Isolation
- `eai-network`: Cross-Stack Kommunikation
- `monitoring-network`: Monitoring-interne Kommunikation
- Verschlüsselte Overlay-Netzwerke

### Health Checks
Alle Services haben konfigurierte Health Checks:
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
  interval: 30s
  timeout: 10s
  retries: 3
```

## 🚀 Development Workflow

### Neuen Adapter hinzufügen

1. **Adapter-Code entwickeln** in `eai-adapters/my-adapter/`
2. **Service in eai-stack.yml definieren:**
```yaml
eai-adapter-myservice:
  image: eai-adapter-myservice:latest
  environment:
    - SPRING_PROFILES_ACTIVE=swarm
  deploy:
    labels:
      - traefik.enable=true
      - traefik.http.routers.eai-adapter-myservice.rule=Host(`adapter-myservice.localhost`)
      - prometheus.scrape=true
      - eai.adapter.type=myservice
```

3. **Deployment:**
```bash
./deploy-multistack.sh deploy-eai
```

### CI/CD Integration
```yaml
# .github/workflows/deploy.yml
name: Deploy EAI Multi-Stack
on:
  push:
    branches: [main]
jobs:
  deploy:
    steps:
      - name: Deploy Monitoring
        run: ./deploy-multistack.sh deploy-monitoring
      - name: Deploy EAI
        run: ./deploy-multistack.sh deploy-eai
```

## 🔍 Troubleshooting

### Häufige Probleme

**Service Discovery funktioniert nicht:**
```bash
# Prometheus Targets prüfen
curl http://prometheus.localhost:9090/api/v1/targets

# Service Labels prüfen
docker service inspect eai-stack_eai-adapter-sample --format '{{.Spec.Labels}}'
```

**Cross-Stack Kommunikation:**
```bash
# Netzwerk-Konnektivität testen
docker exec $(docker ps -q -f name=prometheus) ping eai-adapter-sample

# Service Logs prüfen
./deploy-multistack.sh logs prometheus monitoring-stack
./deploy-multistack.sh logs eai-adapter-sample eai-stack
```

### Debug-Befehle
```bash
# Stack-Status
./deploy-multistack.sh status

# Service-Details
docker service ps monitoring-stack_prometheus --no-trunc
docker service ps eai-stack_eai-adapter-sample --no-trunc

# Netzwerk-Analyse
docker network inspect eai-network
```

## 📚 Dateien-Übersicht

```
eai-docker-swarm/
├── monitoring-stack.yml          # Monitoring Services
├── eai-stack.yml                 # EAI Services
├── deploy-multistack.sh          # Multi-Stack Deployment Script
├── prometheus/
│   ├── prometheus.yml            # Prometheus Konfiguration
│   └── alerts/
│       └── eai-alerts.yml        # Alert Rules
├── grafana/
│   ├── provisioning/             # Grafana Auto-Provisioning
│   └── dashboards/               # EAI Dashboards
├── alertmanager/
│   └── alertmanager.yml          # Alert Routing
├── database/
│   └── init/
│       └── 01-init-schema.sql    # DB Schema
├── configs/
│   ├── eai-global-config.yml     # Globale EAI Konfiguration
│   └── logback-spring.xml        # Logging Konfiguration
└── eai-adapters/                 # Adapter Source Code
    ├── sample/
    ├── orders/
    └── products/
```

## 🤝 Contribution

Beiträge sind willkommen! Bitte beachten Sie:

1. **Feature Branches** für neue Funktionen
2. **Testing** aller neuen Adapter
3. **Documentation** Updates
4. **Monitoring** Metriken für neue Services

### Code Standards
- Spring Boot + Apache Camel für EAI Adapter
- Prometheus Metriken für alle Services
- Health Checks für alle Services
- Strukturiertes JSON Logging

## 📄 Migration von Single-Stack

Falls Sie von der alten Single-Stack Version migrieren:

1. **Backup** der aktuellen Konfiguration
2. **Neue Dateien** mit `deploy-multistack.sh` verwenden
3. **Stacks getrennt deployen** für Zero-Downtime Migration
4. **Monitoring** während der Migration

## 🔄 Updates & Wartung

### Stack Updates
```bash
# Monitoring Stack Update
./deploy-multistack.sh restart monitoring

# EAI Stack Update
./deploy-multistack.sh restart eai

# Rolling Update einzelner Services
./deploy-multistack.sh update eai-adapter-sample eai-adapter-sample:v2 eai-stack
```

### Backup & Recovery
```bash
# Volume Backup
docker run --rm -v prometheus-data:/data -v $(pwd):/backup alpine tar czf /backup/prometheus-backup.tar.gz /data

# Restore
docker run --rm -v prometheus-data:/data -v $(pwd):/backup alpine tar xzf /backup/prometheus-backup.tar.gz -C /data --strip 1
```

## 📞 Support

Bei Fragen oder Problemen:
- Erstellen Sie ein GitHub Issue
- Prüfen Sie die Debug-Befehle in der Dokumentation
- Verwenden Sie `./deploy-multistack.sh info` für Service-URLs

---

**Version**: 2.0.0 - Multi-Stack Architecture  
**Lizenz**: MIT
