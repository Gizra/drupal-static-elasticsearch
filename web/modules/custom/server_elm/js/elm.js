/**
 * @file
 *  Elm Job application.
 */

(function ($, Drupal) {

  const searchUrl = 'https://drupal-static-elasticsearch.ddev.site:9201';

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
          searchUrl : searchUrl
        }});
        switch (page) {
          case 'elasticsearch':
            break;
        }
      });
    }
  };

})(jQuery, Drupal);
