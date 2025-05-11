#!/bin/bash

# @brief: Build script for the website
# @details: It copies `./content/*` to `./artifact/`
# @version: 0.1.0

if [ ! -d ./artifact ]; then
    mkdir ./artifact
else
    rm -rf ./artifact/*
fi

cp -r ./content/* ./artifact/
