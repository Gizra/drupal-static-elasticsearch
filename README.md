# Drupal 8 Starter

Starter repo for Drupal 8 development

## Requirements

* [DDEV](https://ddev.readthedocs.io/en/stable/)

## Installation

    ddev composer install
    cp .ddev/config.local.yaml.example .ddev/config.local.yaml
    ddev restart


### Troubleshooting

If you had a previous installation of this repo, and have an error similar to `composer [install] failed, composer command failed: failed to load any docker-compose.*y*l files in /XXX/multi-repo/.ddev: err=<nil>. stderr=`

then execute the following, and re-try installation steps.

    ddev rm --unlist

## Create Site Snapshot

1. Clear cache.
1. Export Static site.
1. Create Elasticsearch index clone with a unique identifier (timestamp).
1. Add the new Elasticsearch index url to the JS file of the Elm app.

    ./vendor/bin/robo snapshot:create

