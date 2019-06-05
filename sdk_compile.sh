#!/usr/bin/env bash
cp -r /work/helloworld package
make package/helloworld/compile V=99
cp bin/ar71xx/packages/base/helloworld_1_ar71xx.ipk /work
