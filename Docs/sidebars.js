module.exports = {
  docs: [
    {
      type: 'category',
      label: 'Introduction',
      collapsed: false,
      items: [
        'motivation',
        'store/Overview',
        'demo',
        'installation',
        'store/BasicUsage',
        'store/advanced-usage',
      ],
    },
    {
      type: 'category',
      label: 'Store',
      collapsed: false,
      items: [
        'store/Overview',
        {
          type: 'category',
          label: 'Core concepts',
          collapsed: false,
          items: [
            'store/core/store',
            'store/core/state',
            'store/core/activity',
            'store/core/extended-computed-property',
            'store/core/mutation',
            'store/core/changes',
            'store/core/derived',
            'store/core/dispatcher',
          ],
        },
        {
          type: 'category',
          label: 'Use in UIKit',
          collapsed: false,
          items: [
            'store/uikit/using-in-uikit',
            'store/uikit/viewmodel-in-uikit',
            'store/uikit/using-with-collection-view',
          ],
        },
        {
          type: 'category',
          label: 'Techniques',
          collapsed: false,
          items: [
            'store/techniques/store-middleware',
            'store/core/logging',
            'store/techniques/optimization-tips',
            'store/techniques/utilities',
          ],
        },
        'store/migrate-from-classic',
      ],
    },
    {
      type: 'category',
      label: 'ORM',
      collapsed: false,
      items: [
        'orm/Overview',
        {
          type: 'category',
          label: 'Docs',
          collapsed: false,
          items: [
            'orm/index-table',
            'orm/middleware',
            'orm/making-derived',
            'orm/tips',
          ],
        },
      ],
    },
  ],
};
