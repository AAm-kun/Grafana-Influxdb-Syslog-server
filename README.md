# Syslog Server with InfluxDB 3 Core

A Docker Compose stack that receives syslog over UDP, stores messages in InfluxDB 3 Core, and displays them in Grafana. The included dashboard is designed for this InfluxDB 3 setup.

## Data flow

`Devices --UDP/514--> Syslog-ng --TCP/6514--> Telegraf --> InfluxDB 3 Core`

Grafana queries InfluxDB 3 over SQL. Syslog-ng handles incoming UDP messages and forwards them to Telegraf, which parses and writes them to the `syslog` database.

## Start the stack

Requirements: Docker Engine and Docker Compose.

1. Clone this branch and enter the directory:

   ```bash
   git clone --branch v3 https://github.com/AAm-kun/Grafana-Syslog-server.git
   cd Grafana-Syslog-server
   ```

2. Optionally set InfluxDB settings before starting. `INFLUXDB_DATABASE` defaults to `syslog`; `INFLUXDB_RETENTION` is optional. For a fixed admin token, set `INFLUXDB_ADMIN_TOKEN` to a secure value. If it is unset, the InfluxDB startup script generates a token.

3. Start the services:

   ```bash
   docker compose up -d
   ```

   To retrieve the generated token, check the InfluxDB container logs:

   ```bash
   docker compose logs influxdb
   ```

   The startup script prints the admin token. Keep it private; Grafana needs it to query the database.

## Configure Grafana

Open [http://localhost:3000](http://localhost:3000) and sign in with Grafana's initial credentials (`admin` / `admin`), then change the password when prompted.

### Add the InfluxDB data source

In Grafana, add an **InfluxDB** data source and configure it for InfluxDB 3:

- **Query language:** SQL
- **URL:** `http://influxdb:8181`
- **Database:** `syslog` (or the value of `INFLUXDB_DATABASE`)
- **Authentication token:** the token printed in the InfluxDB container logs, or the value you set in `INFLUXDB_ADMIN_TOKEN`

Save and test the data source. Grafana and InfluxDB communicate over the Compose network, so use `influxdb:8181` as the URL from Grafana.

### Import the dashboard included in this repository

Do not use the Grafana.com syslog dashboard: it is not the dashboard for this InfluxDB 3 configuration.

1. In Grafana, go to **Dashboards → New → Import**.
2. Upload `grafana-dashboard-influxdb-v3.json` from the repository (or paste its contents).
3. If prompted, select the InfluxDB data source you configured, then import.

The dashboard contains SQL queries for the `syslog` database and panels for message counts and recent messages.

## Send syslog messages

Configure your devices to send syslog over UDP to the Docker host's IP address on port `514`. The Compose file maps this to Syslog-ng's UDP listener.

## Optional settings

You can set these environment variables before running `docker compose up -d`:

- `INFLUXDB_ADMIN_TOKEN`: fixed admin token; if omitted, one is generated at startup.
- `INFLUXDB_DATABASE`: database name; defaults to `syslog`.
- `INFLUXDB_RETENTION`: optional database retention period.
