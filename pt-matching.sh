#!/bin/bash

java -Xmx5g -cp build/install/ptanalysis/lib/\*  blang.runtime.Runner \
    --engine ptbm.OptPT "$@"