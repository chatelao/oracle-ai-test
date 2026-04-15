# LLM x Oracle SQLcl Integration Test

Dieses Repository dient dem Testen des Zusammenspiels eines lokalen LLM mit einer Oracle Datenbank via SQLcl.

## Ziele
- Integration eines lokalen LLM in Datenbank-Workflows.
- Automatisierte SQL-Generierung und -Ausführung.
- Validierung der Ergebnisse durch automatisierte Tests.

## Struktur
- `ROADMAP.md`: Zentraler Projektplan und Meilensteine.
- `README.md`: Diese Zusammenfassung.
- `test.sh`: Haupt-Testskript gegen LLM und DB.
- `docker-compose.yml`: Container-Orchestrierung für Oracle DB und Ollama.
- `/install`: Verzeichnis für Installationsskripte der einzelnen Komponenten.
- `.github/workflows`: CI/CD Workflow zur Testautomatisierung.

## Schnellstart

### 1. Umgebung starten
Um die Datenbank und Ollama zu starten, verwende Docker Compose:
```bash
docker compose up -d
```

### 2. LLM Modell vorbereiten
Stelle sicher, dass Ollama läuft und lade das gewünschte Modell:
```bash
docker exec -it ollama ollama pull llama3
```

### 3. Datenbank konfigurieren
Passe die Verbindungsinformationen in `install/db_config.sh` an, falls nötig. Standardmäßig sind sie auf die Docker-Instanz eingestellt.

### 4. Tests ausführen
Starte das Haupt-Testskript:
```bash
bash test.sh
```
Die Ergebnisse werden in `test-report.md` gespeichert.
