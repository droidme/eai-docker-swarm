# EAI Docker Swarm Umgebung

Eine vollständige Docker Swarm Umgebung für Enterprise Application Integration (EAI) mit Spring Boot, Apache Camel, Traefik, Prometheus und Grafana.

## 🚀 Quick Start

1. **Projekt bauen und deployen:**
   ```bash
   ./deploy.sh deploy
   ```

2. **Zugriff auf Services:**
   - Traefik Dashboard: http://localhost:8080
   - Prometheus: http://localhost:9090
   - Grafana: http://localhost:3000 (admin/admin)

3. **EAI Adapter testen:**
   ```bash
   curl http://localhost/api/health
   curl http://localhost/actuator/prometheus
   ```

4. **Stack entfernen:**
   ```bash
   ./deploy.sh cleanup
   ```

## 📁 Projektstruktur

```
eai-docker-swarm/
├── docker-compose.yml          # Swarm Stack Definition
├── deploy.sh                   # Deployment Script
├── README.md                   # Diese Datei
├── prometheus/
│   └── prometheus.yml          # Prometheus Konfiguration
├── grafana/
│   ├── dashboards/            # Grafana Dashboards
│   └── provisioning/          # Grafana Konfiguration
└── eai-adapters/
    ├── sample/                # Beispiel EAI Adapter
    │   ├── src/main/java/
    │   ├── src/main/resources/
    │   ├── pom.xml
    │   └── Dockerfile
    └── orders/                # Orders EAI Adapter
        ├── src/main/java/
        ├── src/main/resources/
        ├── pom.xml
        └── Dockerfile
```

## 🛠️ Entwicklung

### Neuen Adapter hinzufügen:
1. Kopiere `eai-adapters/sample` zu `eai-adapters/newadapter`
2. Passe die Konfiguration an
3. Erweitere `docker-compose.yml`
4. Rebuilde mit `./deploy.sh deploy`

### Logs anzeigen:
```bash
docker service logs -f eai-stack_eai-adapter-sample
```

### Services skalieren:
```bash
docker service scale eai-stack_eai-adapter-sample=3
```

## 📊 Monitoring

- **Health Checks:** `/actuator/health`
- **Metriken:** `/actuator/prometheus`
- **Grafana Dashboards:** Vorkonfiguriert für EAI Monitoring

Viel Erfolg mit Ihrer EAI Umgebung! 🎉
