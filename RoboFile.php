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

  const ELASTICSEARCH_INDEX_PREFIX = 'elasticsearch_index_';

  public function staticExport() {
    $siteUrl = $this::SITE_URL;
    $wgetExportDirectory = $this::WGET_EXPORT_DIRECTORY;

    $this->_exec("ddev . drush cr");
    // We don't stop on fail, as we get error code 8.
    $this->_exec("wget --directory-prefix=$wgetExportDirectory --mirror --page-requisites --convert-links --adjust-extension --span-hosts --restrict-file-names=windows --no-parent $siteUrl");

    $this->taskExecStack()
      ->stopOnFail()
      ->exec("find $wgetExportDirectory -type f -name '*.html' -exec sed -i -e \"s/\/index.html/\//g\" {} \;")
      ->run();

    $uniqueIdentifier = time();

    $this->elasticsearchSnapshot($uniqueIdentifier, 'https://drupal-static-elasticsearch.ddev.site:9201');

    $this->taskExecStack()
      ->stopOnFail()
      ->exec("find $wgetExportDirectory -type f -name '*.js' -exec sed -i -e \"s/const indexName = 'elasticsearch_index_db_default';/const indexName = 'elasticsearch_index_$uniqueIdentifier';/g\" {} \;")
      ->run();
  }

  /**
   * Makes a snapshot of the index of the site.
   *
   * @param string $es_url
   *   Fully qualified URL to Elasticsearch, for example:
   *   https://drupal-static-elasticsearch.ddev.site:9201.
   * @param string $username
   *   The username of the Elasticsearch admin user. Defaults to empty string.
   * @param string $password
   *   The password of the Elasticsearch admin user. Defaults to empty string.
   * @param string $index
   *   The index name (without the ELASTICSEARCH_INDEX_PREFIX) to take the
   *   snapshot from. Defaults to `db_default`.
   * @param string $uniqueIdentifier
   *   Optional; The unique identifier reflects the state of the site. If empty
   *   timestamp will be used.
   *
   * @throws \Robo\Exception\TaskException
   */
  public function elasticsearchSnapshot($uniqueIdentifier, $es_url, $username = '', $password= '', $index = 'db_default') {
    $uniqueIdentifier = $uniqueIdentifier ?: time();

    $data_readonly = <<<END
{
  "settings": {
    "index.blocks.write": true
  }
}
END;
    $data_readwrite = <<<END
{
  "settings": {
    "index.blocks.write": false
  }
}
END;
    $this->taskExecStack()
      ->stopOnFail()
      ->exec("curl -u {$username}:{$password} -X PUT {$es_url}/" . self::ELASTICSEARCH_INDEX_PREFIX . $index . "/_settings -H 'Content-Type: application/json' --data '$data_readonly'")
      ->exec("curl -u {$username}:{$password} -X POST {$es_url}/" . self::ELASTICSEARCH_INDEX_PREFIX . $index . "/_clone/" . self::ELASTICSEARCH_INDEX_PREFIX . "_" . $uniqueIdentifier)
      ->exec("curl -u {$username}:{$password} -X PUT {$es_url}/" . self::ELASTICSEARCH_INDEX_PREFIX . $index . "/_settings -H 'Content-Type: application/json' --data '$data_readwrite'")
      ->run();
  }
}

