#!/bin/sh

# Decode private deploy SSH key
openssl aes-256-cbc -k "$travis_key_password" -md sha256 -d -a -in travis_key.enc -out ./travis_key
chmod 400 ./travis_key
echo "Host github.com" > ~/.ssh/config
echo "  IdentityFile $(pwd)/travis_key" >> ~/.ssh/config
git remote set-url origin git@github.com:JuliaEnergy/PowerDynamicsExamples.git

git diff --name-status
# test connection
git remote -v
ssh -T git@github.com
