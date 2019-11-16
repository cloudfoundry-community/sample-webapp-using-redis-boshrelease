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

### Create Fissile image

```plain
bosh create-release \
    releases/sample-webapp-using-redis/sample-webapp-using-redis-1.0.0.yml \
    --tarball tmp/sample-webapp-using-redis-1.0.0.tgz

fissile build release-images \
    --stemcell splatform/fissile-stemcell-opensuse:42.3-38.g82067a9-30.95 \
    --name sample-webapp-using-redis
    --version $(bosh int <(tar Oxzf tmp/sample-webapp-using-redis-*.tgz release.MF) --path /version) \
    --url tmp/sample-webapp-using-redis-*.tgz \
    --sha1 $(sha1sum tmp/sample-webapp-using-redis-*.tgz | awk '{print $1}') \
    -w $PWD/tmp/fissile \
    --final-releases-dir releases
```