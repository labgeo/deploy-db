#!/bin/bash

echo -e "\n=================================="
echo -e "\ndeploy-db"
echo -e "\n=================================="
echo -e "\nDeploy a PostGIS database over your docker infraestructure."
echo "Use this tool to run a PostgreSQL/PostGIS docker container"
echo "and restore data from a plain text dump file."

echo -e "\nThis tool depends on psql. Run:"
echo -e "\n$ apt-get install postgresql-client"
echo -e "\nto install this package on a Debian system."

echo -e "\nPlease, make sure you run deploy-db as a user who is"
echo "a member of the docker group."

# Script args are handled using getopt.
# Code based on Robert Siemer's answer to question
# 'How do I parse command line arguments in bash?' on SO
# (see http://stackoverflow.com/a/29754866).
getopt --test > /dev/null
if [[ $? != 4 ]]; then
    echo "`getopt --test` failed in this environment."
    exit 1
fi

SHORT=v:i:p:D:P:h
LONG=volume:,image:,port:,database:,password:,help,skip

PARSED=`getopt --options $SHORT --longoptions $LONG --name "$0" -- "$@"`
if [[ $? != 0 ]]; then
    exit 2
fi
eval set -- "$PARSED"
p="5432"
while true; do
  case "$1" in
    -v|--volume)
      v="$2"
      shift 2
      ;;
    -i|--image)
      i="$2"
      shift 2
      ;;
    --skip)
      skip=y
      shift
      ;;
    -p|--port)
      p="$2"
      shift 2
      ;;
    -D|--database)
      D="$2"
      shift 2
      ;;
    -P|--password)
      P="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    -h|--help)
      h=y
      shift
      break
      ;;
    *)
      echo "Invalid argument $1"
      exit 3
      ;;
    esac
done

# Portable syntax to evaluate if variable is defined and not empty.
# Based on Gilles' answer to question
# 'How to test if a variable is defined at all in Bash?' on StackExchange
# (see http://unix.stackexchange.com/a/56846).
if [ -n "${h:+1}" ]; then
  echo -e "\nUsage: deploy-db.sh [OPTION]... DUMP_FILE"
  echo -e "\nOptions:"
  echo "  -v,--volume[=VOLUME_NAME]        Docker volume name to be created or reused if "
  echo "                                   --skip option is chosen. In either case"
  echo "                                   VOLUME_NAME is required"
  echo "  --skip                           Skip volume creation"
  echo "  -i,--image[=IMAGE_NAME]          Docker image name (required)"
  echo "  -p,--port[=PORT]                 PostgreSQL server mapped port (default is '5432')"
  echo "  -D,--database[=DBNAME]           Database name (required)"
  echo "  -P,--password[=PASSWORD]         'postgres' user password (required)"
  echo "  -h,--help                        Show this help and exit"
  exit 4
fi
if [[ $# != 1 ]]; then
  echo -e "\nMISSING ARGUMENT: A single dump filename is required."
  exit 5
fi

if ! [ -n "${v:+1}" ]; then
  echo -e "\nMISSING ARGUMENT: Please provide a Docker volume name with -v."
  exit 6
fi

if ! [ -n "${i:+1}" ]; then
  echo -e "\nMISSING ARGUMENT: Please provide a Docker image name with -i."
  exit 7
fi

if ! [ -n "${D:+1}" ]; then
  echo -e "\nMISSING ARGUMENT: Please provide a database name with -D."
  exit 8
fi

if ! [ -n "${P:+1}" ]; then
  echo -e "\nMISSING ARGUMENT: Please provide 'postgres' user password with -P."
  exit 9
fi

START=$(date +'%s')
if ! [ -n "${skip:+1}" ]; then
  echo -e "\nCreating volume $v"
  docker volume create --name $v
fi
echo -e "\nRunning docker container from image $i"
docker run -d -p $p:5432 -e POSTGRES_PASSWORD=$P -v $v:/var/lib/postgresql/data $i
# Wait for postgresql service to get running
sleep 15
echo -e "\nCreating database $D"
PGPASSWORD=$P psql -h localhost -p $p -U postgres -w <<EOSQL
CREATE DATABASE $D;
\c $D
CREATE EXTENSION postgis;
\q
EOSQL
DUMP_FILE=$1
echo -e "\nLoading data from $DUMP_FILE"
PGPASSWORD=$P psql -h localhost -p $p -d $D -U postgres -f $DUMP_FILE -w --quiet
echo -e "\nVacuuming"
PGPASSWORD=$P psql -h localhost -p $p -d $D -U postgres -w -c "VACUUM ANALYZE" --quiet
echo -e "Total elapsed time: $(($(date +'%s') - $START)) secs"
