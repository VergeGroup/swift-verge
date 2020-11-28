module.exports = {
  docs: [{
      type: 'category',
      label: 'Verge',
      collapsed: false,
      items: [
        'installation',
        'motivation',
        'Overview',
        'demo',
      ]
    },
    {
      type: 'category',
      label: 'VergeStore',
      collapsed: false,
      items: [
        'VergeStore/BasicUsage',
        'VergeStore/advanced-usage',
        {
          type: 'category',
          label: 'Docs',
          collapsed: false,
          items: [
            'VergeStore/store',          
            'VergeStore/state',
            'VergeStore/activity',
            'VergeStore/extended-computed-property',
            'VergeStore/mutation',
            'VergeStore/changes',
            'VergeStore/derived',
            'VergeStore/dispatcher',
            'VergeStore/logging',
            'VergeStore/utilities',
            'VergeStore/optimization-tips',
          ],

        },
        {
          type: 'category',
          label: 'Use in UIKit',
          collapsed: false,
          items: [
            'VergeStore/UIKit/using-in-uikit',
            'VergeStore/UIKit/viewmodel-in-uikit',
            'VergeStore/UIKit/using-with-collection-view'
          ],

        },
        'VergeStore/migrate-from-classic',
      ]
    },
    {
      type: 'category',
      label: 'VergeORM',
      collapsed: false,
      items: [
        'VergeORM/Overview',
        {
          type: 'category',
          label: 'Docs',
          collapsed: false,
          items: [
            'VergeORM/index-table',
            'VergeORM/middleware',
            'VergeORM/making-derived',
            'VergeORM/tips',
          ],

        },
      ]
    }
  ]
};
