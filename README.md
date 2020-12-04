# Build environments and images

This is the location where build scripts for EOSIO related tools are kept.

To launch the build, simply push your work to the a remote `build/<...>` branch.
Our Google Cloudbuild project is notified when a push on a `build/<...>` branch
is detected, effectively building the given project.

Actual branches (re-run to see actual values):

```
$ git branch -r | grep build/ | sed s'/origin\///'g
  build/bos-dm
  build/bos-vanilla
  build/eos-dm
  build/eos-vanilla
  build/eosio-buildenv
  build/eosio-cdt
  build/wax-dm
  build/wax-vanilla
```

List the available build envs:

    gcloud container images list-tags gcr.io/eoscanada-shared-services/eosio-buildenv

Boot one locally:

    docker run --name eos-buildenv -ti -v `pwd`:`pwd` -w `pwd` gcr.io/eoscanada-shared-services/eosio-buildenv:v2.0.0 /bin/bash


### Updating EOSIO version

Let's assuming you want to update EOSIO vanilla version to `v2.0.3` and the Deep Mind
version to `v2.0.3-dm-v10.4`.

1. Open `./cloudbuild-eos-vanilla.yaml`
1. Change `_TAG: vX` to `_TAG: v2.0.3`

1. Open `./cloudbuild-eos-dm.yaml`
1. Change `_TAG: vX` to `_TAG: v2.0.3-dm-v10.4`
1. Change `_BRANCH: vX` to `_BRANCH: v2.0.3-dm-v10.4`

Commit those changes on master. Than simply push `master` to `build/eos-vanilla`
and `build/eos-dm` respectively to launch the builds:

```
git push origin -f master:build/eos-vanilla master:build/eos-dm
```

*Warning* We perform a force-push which is correct for `build/<branch>` since they are
used only for trigger purposes. Don't add a plain `master` branch here!
