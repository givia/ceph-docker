#!/bin/bash
set -e

function get_admin_key {
   # No-op for static
   echo "k8s: does not generate admin key. Use secrets instead."
}

function get_mon_config {

  DEPLOYID=$(hostname | cut -d '-' -f3)
  HOSTIP=$(hostname -I | cut -d' ' -f1)
  HOSTNAME=$(hostname)
  i=0
  INSERTED="0"
  HOSTIP1=$(echo ${HOSTIP} | cut -d'.' -f1 | cut -d ' ' -f1)
  HOSTIP2=$(echo ${HOSTIP} | cut -d'.' -f2 | cut -d ' ' -f1)
  HOSTIP3=$(echo $HOSTIP | cut -d'.' -f3 | cut -d ' ' -f1)
  HOSTIP4=$(echo $HOSTIP | cut -d'.' -f4 | cut -d ' ' -f1)

  etcdctl  --endpoint 172.19.1.11:4001 rm --dir=true --recursive=true /skydns/cafecluster/svc/ || true

  curl -XPUT http://172.19.1.11:4001/v2/keys/skydns/arpa/in-addr/$HOSTIP1/$HOSTIP2/$HOSTIP3/$HOSTIP4 -d value="{\"host\":\"$HOSTNAME\"}"


  for ep in $(kubectl get ep ceph-mon --namespace ceph -o template --template '{{range .subsets}}{{range .addresses}}{{.ip}} {{end}}{{end}}' | cut -d " " -f1-); do
    i=$(($i+1))
    curl -XPUT http://172.19.1.11:4001/v2/keys/skydns/cafecluster/svc/ceph/ceph-mon/x${i} -d value="{\"host\":\"${ep}\"}"
  done;

  echo "search ceph.svc.cafecluster svc.cafecluster cafecluster" > /etc/resolv.conf
  echo "nameserver 172.19.1.11" >> /etc/resolv.conf
  echo "options ndots:5" >> /etc/resolv.conf


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

