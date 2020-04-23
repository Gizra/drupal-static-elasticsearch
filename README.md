# Drupal Static, with Elasticsearch

Based on top of [Gizra/drupal-starter](https://github.com/Gizra/drupal-starter)

## Requirements

* [DDEV](https://ddev.readthedocs.io/en/stable/)

## Installation

    ddev composer install
    cp .ddev/config.local.yaml.example .ddev/config.local.yaml
    ddev restart

## Create Site Snapshot

    ./vendor/bin/robo snapshot:create

Command will:

1. Clear cache.
1. Export Static site.
1. Create Elasticsearch index clone with a unique identifier (timestamp).
1. Add the new Elasticsearch index url to the JS file of the Elm app.



