#!/bin/bash
set -e

function get_admin_key {
   # No-op for static
   echo "k8s: does not generate admin key. Use secrets instead."
}

function get_mon_config {
  # Get FSID from ceph.conf
  FSID=$(ceph-conf --lookup fsid -c /etc/ceph/ceph.conf)

  # Get the ceph mon pods (name and IP) from the Kubernetes API. Formatted as a set of monmap params
  MONMAP_ADD=$(LOCALIP=`hostname -I | cut -d' ' -f1` kubectl --namespace ceph get pods -l daemon=mon -o template --template='{{range .items}}{{if .status.podIP}} --add {{.metadata.name}} {{ if ne .status.podIP "${LOCALIP}" }}{{ .status.podIP }}{{else}}127.0.0.1{{end}}{{end}}{{end}}')

  # Create a monmap with the Pod Names and IP
  monmaptool --create ${MONMAP_ADD} --fsid ${FSID} /etc/ceph/monmap-${CLUSTER}

}

function get_config {
   # No-op for static
   echo "k8s: config is stored as k8s secrets."
}

