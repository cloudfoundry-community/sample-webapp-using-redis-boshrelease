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
helm install quarks/helm/sample-webapp-using-redis --generate-name -n scf
```

The helm chart currently assumes an older cf-operator with CRD's `fissile.cloudfoundry.org`.

If you are testing this chart against latest cf-operator, then you can select the new apiVersion:

```plain
helm install quarks/helm/sample-webapp-using-redis --generate-name -n scf \
    --set quarks.apiVersion=quarks.cloudfoundry.org/v1alpha1
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

Next, update the `quarks/helm/sample-webapp-using-redis/Chart.yaml` with the new version:

```yaml
version: 1.0.1
appVersion: 1.0.1
```
