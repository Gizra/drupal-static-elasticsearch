<?php

/**
 * This is project's console commands configuration for Robo task runner.
 *
 * @see http://robo.li/
 */
class RoboFile extends \Robo\Tasks
{

  const OPTIMIZED_FORMATTER = 'ScssPhp\ScssPhp\Formatter\Crunched';

  const DEV_FORMATTER = 'ScssPhp\ScssPhp\Formatter\Expanded';

  const THEME_BASE = 'web/themes/custom/theme_server';

  /**
   * The Pantheon name.
   *
   * You need to fill this information for Robo to know what's the name of your
   * site.
   */
  const PANTHEON_NAME = '';

  /**
   * Static site related data.
   */
  const SITE_URL = 'https://drupal-static-elasticsearch.ddev.site:4443';

  const WGET_EXPORT_DIRECTORY = '.wget-export';

  const ELASTICSEARCH_INDEX_PREFIX = 'elasticsearch_index_';

  public function snapshotCreate() {
    $siteUrl = $this::SITE_URL;
    $wgetExportDirectory = $this::WGET_EXPORT_DIRECTORY;

    $parse = parse_url($siteUrl);
    $domain = $parse['host'];

    $this->_exec("drush cr");

    $this->_cleanDir($wgetExportDirectory);

    // We don't stop on fail, as we get error code 8 from wget.
    $this->_exec("wget --directory-prefix=$wgetExportDirectory --mirror --page-requisites --convert-links --adjust-extension --span-hosts --restrict-file-names=windows --no-parent --domains=$domain $siteUrl");

    // Remove `index.html` from a URL. That is `/content/foo/index.html` becomes
    // `/content/foo`
    $this->taskExecStack()
      ->stopOnFail()
      ->exec("find $wgetExportDirectory -type f -name '*.html' -exec sed -i -e \"s/\/index.html/\//g\" {} \;")

      // Change in `elm.js` a variable to let Elm app know we're under static
      // context.
      ->exec("find $wgetExportDirectory/*/sites/default/files/js -type f -name '*.js' -exec sed -i -e \"s/const isElmRunningInStaticContext = false;/const isElmRunningInStaticContext = true;/g\" {} \;")
      ->run();

    return;

    $uniqueIdentifier = time();

    $this->elasticsearchSnapshot($uniqueIdentifier, 'https://drupal-static-elasticsearch.ddev.site:9201');

    $this->taskExecStack()
      ->stopOnFail()
      ->exec("find $wgetExportDirectory -type f -name '*.js' -exec sed -i -e \"s/const indexName = 'elasticsearch_index_db_default';/const indexName = 'elasticsearch_index_$uniqueIdentifier';/g\" {} \;")
      ->run();

    $httpServerCommand = 'npx http-server /var/www/html/.wget-export/drupal-static-elasticsearch.ddev.site+4443/';

    $runHttpServerConfirm = $this->confirm('Run local server to view newly created static site?');
    if ($runHttpServerConfirm) {
      $this->_exec($httpServerCommand);
    }
    else {
      $this->yell("Snapshot created, you can view it locally by executing:                           ");
      $this->yell("ddev . npx http-server ../.wget-export/drupal-static-elasticsearch.ddev.site+4443/");
    }
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
      ->exec("curl -u {$username}:{$password} -X POST {$es_url}/" . self::ELASTICSEARCH_INDEX_PREFIX . $index . "/_clone/" . self::ELASTICSEARCH_INDEX_PREFIX . $uniqueIdentifier)
      ->exec("curl -u {$username}:{$password} -X PUT {$es_url}/" . self::ELASTICSEARCH_INDEX_PREFIX . $index . "/_settings -H 'Content-Type: application/json' --data '$data_readwrite'")
      ->run();
  }

  /**
   * Compile the app; On success ...
   *
   * @param bool $optimize
   *   Indicate whether to optimize during compilation.
   */
  private function compileTheme_($optimize = FALSE) {
    // Stylesheets.
    $formatter = self::DEV_FORMATTER;
    if ($optimize) {
      $formatter = self::OPTIMIZED_FORMATTER;
    }

    $directories = [
      'css',
      'js',
      'images',
    ];

    // Cleanup directories.
    foreach ($directories as $dir) {
      $directory = self::THEME_BASE . '/dist/' . $dir;
      $this->taskCleanDir($directory);
      $this->_mkdir($directory);
    }

    $compiler_options = [];
    if (!$optimize) {
      $compiler_options['sourceMap'] = Compiler::SOURCE_MAP_INLINE;
    }

    // CSS.
    $result = $this->taskScss([
      self::THEME_BASE . '/src/scss/style.scss' => self::THEME_BASE . '/dist/css/style.css',
    ])
      ->setFormatter($formatter)
      ->importDir([self::THEME_BASE . '/src/scss'])
      ->compiler('scssphp', $compiler_options)
      ->run();

    if ($result->getExitCode() !== 0) {
      $this->taskCleanDir(['dist/css']);
      return $result;
    }

    // Javascript.
    if ($optimize) {
      // Minify the JS files.
      foreach (glob(self::THEME_BASE . '/src/js/*.js') as $js_file) {

        $to = $js_file;
        $to = str_replace('/src/', '/dist/', $to);

        $this->taskMinify($js_file)
          ->to($to)
          ->type('js')
          ->singleLine(TRUE)
          ->keepImportantComments(FALSE)
          ->run();
      }
    }
    else {
      $this->_copyDir(self::THEME_BASE . '/src/js', self::THEME_BASE . '/dist/js');
    }

    // Images - Copy everything first.
    $this->_copyDir(self::THEME_BASE . '/src/images', self::THEME_BASE . '/dist/images');

    // Then for the formats that we can optimize, perform it.
    if ($optimize) {
      $input = [
        self::THEME_BASE . '/src/images/*.jpg',
        self::THEME_BASE . '/src/images/*.png',
      ];

      $this->taskImageMinify($input)
        ->to(self::THEME_BASE . '/dist/images/')
        ->run();
    }
  }

  /**
   * Compile the theme (optimized).
   */
  public function themeCompile() {
    $this->say('Compiling (optimized).');
    $this->compileTheme_(TRUE);
  }

  /**
   * Compile the theme.
   *
   * Non-optimized.
   */
  public function themeCompileDebug() {
    $this->say('Compiling (non-optimized).');
    $this->compileTheme_();
  }

  /**
   * Directories that should be watched for the theme.
   *
   * @return array
   *  List of directories.
   */
  protected function monitoredThemeDirectories() {
    return [
      self::THEME_BASE . '/src',
    ];
  }

  /**
   * Watch the theme and compile on change (optimized).
   */
  public function themeWatch() {
    $this->say('Compiling and watching (optimized).');
    $this->compileTheme_(TRUE);
    foreach ($this->monitoredThemeDirectories() as $directory) {
      $this->taskWatch()
        ->monitor(
          $directory,
          function (Event $event) {
            $this->compileTheme_(TRUE);
          },
          FilesystemEvent::ALL
        )->run();
    }
  }

  /**
   * Watch the theme path and compile on change (non-optimized).
   */
  public function themeWatchDebug() {
    $this->say('Compiling and watching (non-optimized).');
    $this->compileTheme_();
    foreach ($this->monitoredThemeDirectories() as $directory) {
      $this->taskWatch()
        ->monitor(
          $directory,
          function (Event $event) {
            $this->compileTheme_();
          },
          FilesystemEvent::ALL
        )->run();
    }
  }

  /**
   * Deploy to Pantheon.
   *
   * @param string $branchName
   *   The branch name to commit to. Default to master.
   *
   * @throws \Exception
   */
  public function deployPantheon($branchName = 'master') {
    if (empty(self::PANTHEON_NAME)) {
      throw new Exception('You need to fill the "PANTHEON_NAME" const in the Robo file. so it will know what is the name of your site.');
    }

    $pantheonDirectory = '.pantheon';

    $result = $this
      ->taskExec('git status -s')
      ->printOutput(FALSE)
      ->run();

    if ($result->getMessage()) {
      throw new Exception('The working directory is dirty. Please commit any pending changes.');
    }

    $result = $this
      ->taskExec("cd $pantheonDirectory && git status -s")
      ->printOutput(FALSE)
      ->run();

    if ($result->getMessage()) {
      throw new Exception('The Pantheon directory is dirty. Please commit any pending changes.');
    }

    // Validate pantheon.yml has web_docroot: true
    if (!file_exists($pantheonDirectory . '/pantheon.yml')) {
      throw new Exception("pantheon.yml is missing from the Pantheon directory ($pantheonDirectory)");
    }

    $yaml = Yaml::parseFile($pantheonDirectory . '/pantheon.yml');
    if (empty($yaml['web_docroot'])) {
      throw new Exception("'web_docroot: true' is missing from pantheon.yml in Pantheon directory ($pantheonDirectory)");
    }

    $this->_exec("cd $pantheonDirectory && git checkout $branchName");

    // Compile theme
    $this->compileTheme();

    $rsyncExclude = [
      '.git',
      '.ddev',
      '.idea',
      '.pantheon',
      'sites/default',
      'pantheon.yml',
      'pantheon.upstream.yml',
    ];

    $rsyncExcludeString = '--exclude=' . join(' --exclude=', $rsyncExclude);

    // Copy all files and folders.
    $this->_exec("rsync -az --progress --delete $rsyncExcludeString . $pantheonDirectory");

    // We don't want to change Pantheon's git ignore, as we do want to commit
    // vendor and contrib directories.
    // @todo: Ignore it from rsync, but './.gitignore' didn't work.
    $this->_exec("cd $pantheonDirectory && git checkout .gitignore");

    $this->_exec("cd $pantheonDirectory && git status");

    $commitAndDeployConfirm = $this->confirm('Commit changes and deploy?');
    if (!$commitAndDeployConfirm) {
      $this->say('Aborted commit and deploy, you can do it manually');

      // The Pantheon repo is dirty, so check if we want to clean it up before
      // exit.
      $cleanupPantheonDirectoryConfirm = $this->confirm("Revert any changes on $pantheonDirectory directory (i.e. `git checkout .`)?");
      if (!$cleanupPantheonDirectoryConfirm) {
        // Keep folder as is.
        return;
      }

      // We repeat "git clean" twice, as sometimes it seems that a single one
      // doesn't remove all directories.
      $this->_exec("cd $pantheonDirectory && git checkout . && git clean -fd && git clean -fd && git status");

      return;
    }

    $pantheonName = self::PANTHEON_NAME;
    $pantheonTerminusEnvironment = $pantheonName . '.dev';

    $this
      ->taskExecStack()
      ->exec("cd $pantheonDirectory && git pull && git add . && git commit -am 'Site update' && git push")
      ->exec("terminus remote:drush $pantheonTerminusEnvironment -- cr")

      // A second cache-clear, because Drupal...
      ->exec("terminus remote:drush $pantheonTerminusEnvironment -- cr")
      ->exec("terminus remote:drush $pantheonTerminusEnvironment -- updb -y")

      // A second config import, because Drupal...
      ->exec("terminus remote:drush $pantheonTerminusEnvironment -- cim -y")
      ->exec("terminus remote:drush $pantheonTerminusEnvironment -- cim -y")
      ->run();
  }

  /**
   * Perform a Code sniffer test, and fix when applicable.
   */
  public function phpcs() {
    $standards = [
      'Drupal',
      'DrupalPractice',
    ];

    $commands = [
      'phpcbf',
      'phpcs',
    ];

    $directories = [
      'modules/custom',
      'themes/custom',
      'profiles/custom'
    ];

    $errorCode = null;

    foreach ($directories as $directory) {
      foreach ($standards as $standard) {
        $arguments = "--standard=$standard -p --colors --extensions=php,module,inc,install,test,profile,theme,js,css";

        foreach ($commands as $command) {
          $result = $this->_exec("cd web && $command $directory $arguments");
          if (empty($errorCode) && !$result->wasSuccessful()) {
            $errorCode = $result->getExitCode();
          }
        }
      }
    }

    if (!empty($errorCode)) {
      return new Robo\ResultData($errorCode, 'PHPCS found some issues');
    }
  }
}

