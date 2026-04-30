# Roadmap - LLM und Oracle DB SQLcl Integration

Dieses Projekt zielt darauf ab, das Zusammenspiel zwischen einem lokalen Large Language Model (LLM) und einer Oracle Datenbank über `sqlcl` zu testen und zu automatisieren.

## Meilensteine

### 1. Umgebungsvorbereitung (Environment Setup)
- [x] Auswahl und Setup des lokalen LLM (Ollama).
- [x] Bereitstellung einer Oracle Datenbank (Docker-basiert mit `docker-compose.yml`).
- [x] Installation und Konfiguration von Oracle SQLcl.

### 2. Installationsskripte (/install)
- [x] Skript zur Installation des LLM (verbessert für CI).
- [x] Skript zur Konfiguration der Datenbankverbindung.
- [x] Skript zur Einrichtung von SQLcl (automatisiert für CI).
- [x] Skript zur Installation des SCOTT/TIGER Schemas (`install/scott.sh`).

### 3. Testskript-Entwicklung (test.sh)
- [x] Entwicklung eines Basistests zur Kommunikation mit dem LLM.
- [x] Entwicklung eines Basistests zur Ausführung von SQL-Befehlen via SQLcl.
- [x] Integration: LLM generiert SQL, SQLcl führt es aus, Ergebnisse werden validiert.
- [x] Integration: LLM generiert SQL gegen das SCOTT Schema und SQLcl führt es aus.

### 4. CI/CD Integration
- [x] Erstellung eines GitHub Action Workflows.
- [x] Automatisierte Testläufe bei jedem Push (verbessert: Services via Docker, automatisierte Installation).
- [x] Berichterstattung über Testergebnisse (generiert `test-report.md` und zeigt es in GitHub Summaries an).
- [x] Optimierung der CI-Laufzeit durch Caching (Docker Images, SQLcl, LLM Modelle).
- [x] Fehlerbehebung bei der Datenbankverbindung (Umstellung auf `system` User).
- [x] Optimierung des CI/CD Workflows (Disk Cleanup, Readiness Checks, robuste Pfade).

## Fortschrittsbewertung
Der Fortschritt wird durch das Bestehen des `test.sh` Skripts in der CI/CD-Pipeline gemessen. Die Pipeline wurde optimiert, um die notwendige Infrastruktur (Datenbank und LLM) während des Laufs bereitzustellen.
