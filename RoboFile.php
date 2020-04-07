<?php

/**
 * This is project's console commands configuration for Robo task runner.
 *
 * @see http://robo.li/
 */
class RoboFile extends \Robo\Tasks
{

  const SITE_URL = 'https://drupal-static-elasticsearch.ddev.site:4443';

  public function staticExport() {
    $siteUrl = $this::SITE_URL;

    $this->taskExecStack()
      ->stopOnFail()
      ->exec("wget -NmkEpnp $siteUrl")
      ->run();

  }
}
