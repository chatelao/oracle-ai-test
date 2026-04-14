# Roadmap - LLM und Oracle DB SQLcl Integration

Dieses Projekt zielt darauf ab, das Zusammenspiel zwischen einem lokalen Large Language Model (LLM) und einer Oracle Datenbank über `sqlcl` zu testen und zu automatisieren.

## Meilensteine

### 1. Umgebungsvorbereitung (Environment Setup)
- [x] Auswahl und Setup des lokalen LLM (Ollama).
- [x] Bereitstellung einer Oracle Datenbank (Docker-basiert mit `docker-compose.yml`).
- [x] Installation und Konfiguration von Oracle SQLcl.

### 2. Installationsskripte (/install)
- [x] Skript zur Installation des LLM.
- [x] Skript zur Konfiguration der Datenbankverbindung.
- [x] Skript zur Einrichtung von SQLcl.

### 3. Testskript-Entwicklung (test.sh)
- [x] Entwicklung eines Basistests zur Kommunikation mit dem LLM.
- [x] Entwicklung eines Basistests zur Ausführung von SQL-Befehlen via SQLcl.
- [x] Integration: LLM generiert SQL, SQLcl führt es aus, Ergebnisse werden validiert.

### 4. CI/CD Integration
- [x] Erstellung eines GitHub Action Workflows.
- [x] Automatisierte Testläufe bei jedem Push.
- [x] Berichterstattung über Testergebnisse (generiert `test-report.md` und zeigt es in GitHub Summaries an).

## Fortschrittsbewertung
Der Fortschritt wird durch das Bestehen des `test.sh` Skripts in der CI/CD-Pipeline gemessen.
