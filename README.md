# BOSH release for sample-webapp-using-redis

This BOSH release and deployment manifest deploy a cluster of sample-webapp-using-redis.

## Usage

This repository includes base manifests and operator files. They can be used for initial deployments and subsequently used for updating your deployments:

```plain
export BOSH_ENVIRONMENT=<bosh-alias>
export BOSH_DEPLOYMENT=sample-webapp-using-redis
git clone https://github.com/cloudfoundry-community/sample-webapp-using-redis-boshrelease.git
bosh deploy sample-webapp-using-redis-boshrelease/manifests/sample-webapp-using-redis.yml
```

If your BOSH does not have Credhub/Config Server, then remember `--vars-store` to allow generation of passwords and certificates.

### Update

When new versions of `sample-webapp-using-redis-boshrelease` are released the `manifests/sample-webapp-using-redis.yml` file will be updated. This means you can easily `git pull` and `bosh deploy` to upgrade.

```plain
export BOSH_ENVIRONMENT=<bosh-alias>
export BOSH_DEPLOYMENT=sample-webapp-using-redis
cd sample-webapp-using-redis-boshrelease
git pull
cd -
bosh deploy sample-webapp-using-redis-boshrelease/manifests/sample-webapp-using-redis.yml
```

## Kubernetes

## Deploy to Quarks

```plain
helm upgrade --install sample-webapp-using-redis  -n kubecf \
    quarks/helm/sample-webapp-using-redis
```

### Create Fissile image

Download latest release `.tgz` into `tmp/` directory.

```plain
fissile build release-images \
    --stemcell splatform/fissile-stemcell-opensuse:42.3-38.g82067a9-30.95 \
    --docker-organization cfcommunity \
    --name sample-webapp-using-redis \
    --version $(bosh int <(tar Oxzf tmp/sample-webapp-using-redis-*.tgz release.MF) --path /version) \
    --url file://$PWD/$(ls tmp/sample-webapp-using-redis-*.tgz) \
    --sha1 $(sha1sum tmp/sample-webapp-using-redis-*.tgz | awk '{print $1}') \
    -w $PWD/tmp/fissile \
    --final-releases-dir $PWD/tmp/releases

docker push cfcommunity/sample-webapp-using-redis:<tag>
```

Output looks similar to:

```plain
Image Name: sample-webapp-using-redis:opensuse-42.3-38.g82067a9-30.95-7.0.0_360.g0ec8d681-1.0.1
compile: sample-webapp-using-redis/sample-webapp-using-redis
compiling
done:    sample-webapp-using-redis/sample-webapp-using-redis
result   > success: sample-webapp-using-redis/sample-webapp-using-redis
Creating Dockerfile for release sample-webapp-using-redis ...
Building docker image of sample-webapp-using-redis...
```

We can now confirm that the `sample-webapp-using-redis` CLI is installed as a BOSH package under its `bin/` folder:

```plain
$ docker run -ti \
  sample-webapp-using-redis:opensuse-42.3-38.g82067a9-30.95-7.0.0_360.g0ec8d681-1.0.1 \
  ls -lR /var/vcap/packages/sample-webapp-using-redis/bin

/var/vcap/packages/sample-webapp-using-redis/bin:
total 8868
-rwxr-xr-x 1 root root 9080804 Nov 16 22:56 sample-webapp-using-redis
```

### Update Helm Chart

When a new version of the BOSH release is created, in addition to creating the new OCI above with `fissile`, we need to update the Helm chart to use it.

Update the Helm chart's base manifest:

```plain
cp manifests/sample-webapp-using-redis.yml quarks/helm/sample-webapp-using-redis/assets/
```

Next, update the `quarks/helm/sample-webapp-using-redis/Chart.yaml` with the new BOSH release "app" version:

```yaml
appVersion: 1.0.1
```

### Using additional BOSH operator

The helm chart installs all the operators in `quarks/helm/sample-webapp-using-redis/assets/operations` folder, and also applies them all to the `BOSHDeployment`.

We can also add custom BOSH operator patches as additional `ConfigMaps`, and edit the `BOSHDeployment` to use them.

There is an example in `quarks/helm/sample-webapp-using-redis/assets/example-operations/` folder.

The `alternate-counter-key.yml` file is an original BOSH operations file that would patch the `webapp` properties to set the `counter_key` job property.

For us to apply it to our Quarks-deployed `BOSHDeployment`, we need to package it as a ConfigMap, and then edit the BOSHDeployment to use this ConfigMapped ops file.

The `cm-alternate-counter-key.yaml` file is ready with the ops patch already included at `data.ops` key:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ops-alternate-counter-key
data:
  ops: |-
    - type: replace
      path: /instance_groups/name=webapp/jobs/name=sample-webapp-using-redis/properties/counter_key?
      value: new-counter-key
```

To install the ops cm file into Kubernetes:

```plain
kubectl apply -f quarks/helm/sample-webapp-using-redis/assets/example-operations/cm-alternate-counter-key.yaml
```

Now we can edit the `BOSHDeployment`...

```plain
kubectl edit boshdeployment sample-webapp-using-redis-deployment
```

And add `ops-alternate-counter-key` to the list of operations to apply to the base manifest:

```yaml
spec:
  manifest:
    name: sample-webapp-using-redis-bosh-manifest
    type: configmap
  ops:
  - name: ops-manifest-cleanup-for-quarks
    type: configmap
  - name: ops-redis
    type: configmap
  - name: ops-release-images
    type: configmap
  - name: ops-alternate-counter-key
    type: configmap
```

Once we complete the edit, Quarks/cf-operator will create a new pair of statefulsets -- one for each instance group -- and update the pods.

When we ping our webapp service we see that it is now using a new Redis key for the counter, and the counter has been reset to 1:

```plain
$ curl webapp.kubecf.svc.cluster.local:8080
new-counter-key=1
$ curl webapp.kubecf.svc.cluster.local:8080
new-counter-key=2
```

### Additional BOSH operations via Helm upgrade

Alternately, we can upgrade our BOSHDeployment to use additional operations via a Helm value:

```plain
helm upgrade webapp quarks/helm/sample-webapp-using-redis --set operations.custom={ops-alternate-counter-key}
```

### Delete Helm deployment

To delete the deployment resources, and the resulting running pods:

```plain
helm delete sample-webapp-using-redis -n kubecf
```

Note, the persistent volumes (and claim) are not deleted:

```plain
kubectl get pv,pvc -n kubecf
NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                                                          STORAGECLASS   REASON   AGE
persistentvolume/pvc-d9ed4049-01f1-4903-92a2-47bc533c0226   10Gi       RWO            Delete           Bound    kubecf/sample-webapp-using-redis-redis-pvc-sample-webapp-using-redis-redis-0   standard                2m57s

NAME                                                                                          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/sample-webapp-using-redis-redis-pvc-sample-webapp-using-redis-redis-0   Bound    pvc-d9ed4049-01f1-4903-92a2-47bc533c0226   10Gi       RWO            standard       3m
```

These will be reused if you re-deploy your release with the same name.

To delete the volume and claim, delete the claim:

```plain
kubectl delete pvc -n kubecf \
  sample-webapp-using-redis-redis-pvc-sample-webapp-using-redis-redis-0
```
