Deep mind patches
-----------------

Checkout a fresh `eos` repo:
```
cd ~/build
git clone --recursive git@github.com:EOSIO/eos.git
cd eos
```

Follow upstream changes and apply our patch(es):
```
cd ~/build/eos
git submodule update --recursive
```

From this directory, run:
```
./apply.sh ~/build/eos ../patches/deep-mind-v1.4.1-v8.2.patch ../patches/deep-mind-logging-v1.4.1-v8.patch
```

Inspect the output, test `nodeos` against `compare`, extract a new patches with:

```
git diff --cached --ignore-submodules=all > deep-mind.patch

pushd libraries/fc
  git diff --cached --src-prefix=a/libraries/fc/ --dst-prefix=b/libraries/fc/ > ../../deep-mind-logging.patch
popd
```

Inspect the patch, make sure nothing extraneous crept in (whitespace
changes, leftovers, etc..)

Call `submit_nodeos_full.sh`

Testing
--------

Compile battlefield contract if you have changes in it:
```
./battlefield/build.sh
```

Execute the actual tests suite via the [boot/run.sh](./boot/run.sh) file:
```
./boot/run.sh ~/build/eos/build/programs/nodeos/nodeos
```

Contents
--------

* `battlefield/` holds a smart contract that can produce all our instrumentation outputs.
* `boot/` creates a blocklog that executes transactions which provokes what we have instrumented, for testing
* `compare/` allows us to replay the `boot` blocklog against any new `nodeos` releases and check that our instrumentation matches our expectations.
