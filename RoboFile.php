<?php

/**
 * This is project's console commands configuration for Robo task runner.
 *
 * @see http://robo.li/
 */
class RoboFile extends \Robo\Tasks
{

  const SITE_URL = 'https://drupal-static-elasticsearch.ddev.site:4443';

  const WGET_EXPORT_DIRECTORY = '.wget-export';

  public function staticExport() {
    $siteUrl = $this::SITE_URL;
    $wgetExportDirectory = $this::WGET_EXPORT_DIRECTORY;

    $this->_exec("ddev . drush cr");
    // We don't stop on fail, as we get error code 8.
    $this->_exec("wget --directory-prefix=$wgetExportDirectory --mirror --page-requisites --convert-links --adjust-extension --span-hosts --restrict-file-names=windows --no-parent $siteUrl");

    $this->taskExecStack()
      ->stopOnFail()
      ->exec("find $wgetExportDirectory -type f -exec sed -i -e \"s/\/index.html/\//g\" {} \;")
      ->run();

  }
}
