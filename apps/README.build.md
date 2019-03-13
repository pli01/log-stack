# Construction des elements commun log-stack:
```
 make build
```

# Les elements sont:
  - archive du depot git
  - image de la stack de logs EFK: 
  - (elasticsearch,fluentd,kibana,nginx)

# Les elements sont generes dans le repertoire log-stack-build
```
 log-stack-VERSION
 log-stack-${APP_VERSION}-archive.tar.gz
 log-stack-latest-archive.tar.gz
 log-stack-efk-nginx-latest-image.tar
 log-stack-efk-nginx-${APP_VERSION}-image.tar
 log-stack-efk-elasticsearch-latest-image.tar
 log-stack-efk-elasticsearch-${APP_VERSION}image.tar
 log-stack-efk-kibana-latest-image.tar
 log-stack-efk-kibana-${APP_VERSION}image.tar
 log-stack-efk-fluentd-latest-image.tar
 log-stack-efk-fluentd-${APP_VERSION}image.tar

```

# Publication des elements generes
En environnement openstack, les elements sont uploade dans un container swift du tenant de l'environnement

```
# generation d'un token temporaire
eval $(openstack --insecure token issue -f shell -c id -c project_id)
openstack_token=${id:-}
openstack_project_id=${project_id:-}

make publish \
 dml_url="https://object-store.mycloud/v1/AUTH_${openstack_project_id}" \
 openstack_token="${openstack_token}"
)
```
