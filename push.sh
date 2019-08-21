#!/bin/sh

if [[ git status --porcelain --untracked-files=no ]]; then
  # Decode private deploy SSH key
    openssl aes-256-cbc -k "$travis_key_password" -md sha256 -d -a -in travis_key.enc -out ./travis_key
    chmod 400 ./travis_key
    echo "Host github.com" > ~/.ssh/config
    echo "  IdentityFile $(pwd)/travis_key" >> ~/.ssh/config
    git remote set-url origin git@github.com:JuliaEnergy/PowerDynamicsExamples.git
    echo "github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==" > ~/.ssh/known_hosts

    echo "Pushing updated notebooks"
    git add *.ipynb
    git commit -m "Automatic update of notebooks [skip ci]" # skip ci prevents infinite triggering of travis
    git diff-tree --no-commit-id --name-only -r HEAD # list changed files
    git push origin HEAD:$TRAVIS_BRANCH
else
  echo "No changes, nothing to do :)"
fi
