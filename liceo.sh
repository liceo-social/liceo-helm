#!/usr/bin/env bash
set -e 

function redeploy {
    if [ -n "$1" ]; then
        kubectl rollout restart deployment/$1
    else
        echo "liceo.sh redeploy liceo-web|liceo-db"
    fi
}

function log {
    echo "liceo.sh: $1"
}

function list-deployments {
    kubectl get deployments
}

function backup-files {
    if [[ -n "$1" ]]; then
        BACKUP_FILENAME="liceo-fs-$(date +%Y%m%d%H%M).tar.gz"

        log "(backup-files) getting liceo-web pod name"
        POD_WEB_NAME=$(kubectl get pods -l tier=web | tail -1 | awk '{print $1}')

        log "(backup-files) creating tarball file"
        kubectl exec $POD_WEB_NAME -- tar czf $BACKUP_FILENAME $1

        log "(backup-files) copying tarball file to local"
        kubectl cp socseross/$POD_WEB_NAME:$BACKUP_FILENAME $BACKUP_FILENAME
    else
        log "(backup-files) ./liceo.sh backup-files /directorio-remoto-a-guardar"
    fi
}

function backup-db {
    BACKUP_FILENAME="liceo-db-$(date +%Y%m%d%H%M).sql"

    log "(backup-db) getting liceo-db pod name"
    POD_DB_NAME=$(kubectl get pods -l tier=db | tail -1 | awk '{print $1}')

    log "(backup-db) executing db dump"
    kubectl exec $POD_DB_NAME -- pg_dump -U liceo -f /tmp/$BACKUP_FILENAME

    log "(backup-db) copying dump file to local"
    kubectl cp socseross/$POD_DB_NAME:/tmp/$BACKUP_FILENAME $BACKUP_FILENAME
}

function usage {
    echo "liceo.sh redeploy|list|backup-db|backup-files"
}

case $1 in 
    redeploy)
        redeploy $2
        ;;
    list)
        list-deployments
        ;;
    backup-db)
        backup-db
        ;;
    backup-files)
        backup-files $2
        ;;
    *)
    usage
    ;;
esac