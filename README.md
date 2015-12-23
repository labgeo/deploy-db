# deploy-db
*Deploy a PostgreSQL/PostGIS database over your Docker infraestructure.*

Use *deploy-db* to run a new  PostgreSQL/PostGIS Docker container and restore a PostgreSQL/PostGIS plain text backup.

## Executing *deploy-db*
Use `deploy-db.sh` bash script in order to deploy your geodatabase.
Invoke the script with `--help` option for detailed arguments and usage.

## Software requirements
Please ensure you have installed the `postgresql-client` package before running the script.
Since `deploy-db.sh` makes use of the new Docker volume API, it requires Docker version 1.9+. Make sure also that you run `deploy-db.sh` as a user who is a member of the `docker` group.
