[![Build Status](https://travis-ci.com/Gizra/drupal-static-elasticsearch.svg?branch=master)](https://travis-ci.com/Gizra/drupal-static-elasticsearch)

# Drupal Static, with Elasticsearch

Read the [blog post](https://www.gizra.com/content/drupal-static-elasticsearch/).

Scaffolded from [Gizra/drupal-starter](https://github.com/Gizra/drupal-starter).

## Requirements

* [DDEV](https://ddev.readthedocs.io/en/stable/)

Note that the demo app assumes you also have [mkcert](https://ddev.readthedocs.io/en/stable/#linux-mkcert-install-additional-instructions) installed as part of ddev.

## Installation

    ddev composer install
    cp .ddev/config.local.yaml.example .ddev/config.local.yaml
    ddev restart

## Site Snapshot

### Create

    ddev robo snapshot:create

Command will:

1. Clear cache.
1. Export Static site.
1. Create Elasticsearch index clone with a unique identifier (timestamp).
1. Add the new Elasticsearch index url to the JS file of the Elm app.

### View

As the Robo command will indicate, you can view the static site by running:

    ddev . npx http-server ../.wget-export/drupal-static-elasticsearch.ddev.site+4443/

This will start a local http-server, and indicate the URL you can open to view
the site.
