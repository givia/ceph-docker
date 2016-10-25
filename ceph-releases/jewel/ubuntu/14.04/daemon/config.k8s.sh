#!/bin/bash
set -e

function get_admin_key {
   # No-op for static
   echo "k8s: does not generate admin key. Use secrets instead."
}

function get_mon_config {

  HOSTIP1=$(hostname -I | cut -d'.' -f1 | cut -d ' ' -f1)
  HOSTIP2=$(hostname -I | cut -d'.' -f2 | cut -d ' ' -f1)
  HOSTIP3=$(hostname -I | cut -d'.' -f3 | cut -d ' ' -f1)
  HOSTIP4=$(hostname -I | cut -d'.' -f4 | cut -d ' ' -f1)

  i=0
  INSERTED="0"
  while [ ${INSERTED} -lt 1 ]; do
    i=$(($i+1))
    INSERTED=$(curl -L -XGET http://172.19.1.11:4001/v2/keys/skydns/cafecluster/svc/ceph/ceph-mon/x$i --head | grep "404" | wc -l)
  done;

  curl -XPUT http://172.19.1.11:4001/v2/keys/skydns/cafecluster/svc/ceph/ceph-mon/x$i -d value='{\"host\":\"`hostname -I | cut -d' ' -f1`\"}'
  curl -XPUT http://172.19.1.11:4001/v2/keys/skydns/arpa/in-addr/${HOSTIP1}/${HOSTIP2}/${HOSTIP3}/${HOSTIP4} -d value='{\"host\":\"`hostname`\"}'


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

