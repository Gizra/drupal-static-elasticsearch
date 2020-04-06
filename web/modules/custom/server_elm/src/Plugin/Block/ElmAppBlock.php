<?php

namespace Drupal\server_elm\Plugin\Block;

use Drupal\Core\Access\AccessResult;
use Drupal\Core\Block\BlockBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\Core\Session\AccountInterface;
use Drupal\Core\Plugin\ContainerFactoryPluginInterface;
use Drupal\Core\Routing\RouteMatchInterface;
use Drupal\Core\Entity\EntityTypeManagerInterface;
use Drupal\Component\Utility\Html;
use Symfony\Component\DependencyInjection\ContainerInterface;
use Drupal\permanent_entities\Entity\PermanentEntityInterface;

/**
 * Provides the "Elm application" block.
 *
 * @Block(
 *   id = "server_elm_application",
 *   admin_label = @Translation("Elm application Block"),
 * )
 */
class ElmAppBlock extends BlockBase implements ContainerFactoryPluginInterface {

  /**
   * The route match service.
   *
   * @var \Drupal\Core\Routing\RouteMatchInterface
   */
  protected $routeMatcher;

  /**
   * The entity type manager.
   *
   * @var \Drupal\Core\Entity\EntityTypeManagerInterface
   */
  protected $entityTypeManager;

  /**
   * Constructs a new ElmAppBlock object.
   *
   * @param array $configuration
   *   A configuration array containing information about the plugin instance.
   * @param string $plugin_id
   *   The plugin_id for the plugin instance.
   * @param string $plugin_definition
   *   The plugin implementation definition.
   * @param \Drupal\Core\Routing\RouteMatchInterface $route_match
   *   The route match service.
   * @param \Drupal\Core\Entity\EntityTypeManagerInterface $entity_type_manager
   *   The entity type manager.
   */
  public function __construct(
    array $configuration,
    $plugin_id,
    $plugin_definition,
    RouteMatchInterface $route_match,
    EntityTypeManagerInterface $entity_type_manager
  ) {
    parent::__construct($configuration, $plugin_id, $plugin_definition);
    $this->routeMatcher = $route_match;
    $this->entityTypeManager = $entity_type_manager;
  }

  /**
   * {@inheritdoc}
   */
  public static function create(ContainerInterface $container, array $configuration, $plugin_id, $plugin_definition) {
    return new static(
      $configuration,
      $plugin_id,
      $plugin_definition,
      $container->get('current_route_match'),
      $container->get('entity_type.manager')
    );
  }

  /**
   * {@inheritdoc}
   */
  public function blockForm($form, FormStateInterface $form_state) {
    $form = parent::blockForm($form, $form_state);

    $form['application_type'] = [
      '#type' => 'select',
      '#title' => $this->t('Application type'),
      '#options' => [
        'elasticsearch' => $this->t('Elasticsearch'),
      ],
      '#default_value' => $this->configuration['application_type'],
      '#weight' => '0',
    ];

    return $form;
  }

  /**
   * {@inheritdoc}
   */
  public function blockSubmit($form, FormStateInterface $form_state) {
    $this->configuration['application_type'] = $form_state->getValue('application_type');
  }

  /**
   * {@inheritdoc}
   */
  public function build() {
    $app_id = Html::getUniqueId('elm-app');
    $application_type = $this->configuration['application_type'];

    if ($application_type == 'elasticsearch') {
      $library = ['server_elm/elasticsearch'];

      return [
        '#attached' => [
          'drupalSettings' => [
            'elm' => [
              $app_id => [
                'page' => $application_type,
              ],
            ],
          ],
          // @todo: Why do we have to load it via server_elm_preprocess_block()?
          // 'library' => $library,
        ],
        '#markup' => "<div id=\"$app_id\"></div>",
      ];
    }
  }

  /**
   * {@inheritdoc}
   */
  protected function blockAccess(AccountInterface $account) {
    return AccessResult::allowed();
  }
}
