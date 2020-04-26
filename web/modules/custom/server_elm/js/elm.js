/**
 * @file
 *  Elm Job application.
 */

(function ($, Drupal) {

  const searchUrl = 'https://drupal-static-elasticsearch.ddev.site:9201';

  // Determine if the Elm app is running on the static site, or on the Drupal
  // one. This affects for example how we construct the URLs. In drupal we keep
  // the `index.html`, but in the static site (which is assumed to be hosted on
  // gh-pages), we're omitting it.
  const isElmRunningInStaticContext = false;

  // This is the default index we search. When we create a static site, Robo
  // will rake care of replacing the index name with the clone.
  const indexName = 'elasticsearch_index_db_default';

  /**
   * Add the Elm app.
   */
  Drupal.behaviors.JobsEm = {
    attach: function (context, settings) {
      var elmApps = settings.elm;
      // Iterate over the apps.
      Object.keys(elmApps).forEach(function (appName) {

        // appName with unique css ID, e.g. `elm-app--2`.
        var node = document.getElementById(appName);

        if (!node) {
          // We haven't found the div, so prevent an error.
          return;
        }

        // The current app's settings.
        var appSettings = settings.elm[appName];
        var page = appSettings.page;

        const app = Elm.Main.init({node: node, flags: {
          isStatic : isElmRunningInStaticContext,
          searchUrl : searchUrl,
          indexName : indexName
        }});
        switch (page) {
          case 'elasticsearch':
            break;
        }
      });
    }
  };

})(jQuery, Drupal);
