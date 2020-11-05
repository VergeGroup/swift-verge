module.exports = {
  title: 'Verge - Flux for SwiftUI / UIKit',
  tagline: 'A performant flux library for iOS App - SwiftUI / UIKit',
  url: 'https://vergegroup.github.io',
  baseUrl: '/Verge/',
  favicon: 'img/favicon.ico',
  organizationName: 'VergeGroup',
  projectName: 'Verge',
  themeConfig: {
    announcementBar: {
      id: 'support_us',  // Any value that will identify this message.
      content:
          '⭐️ Verge 8 now released.  If you like this, give it a star on <a href="https://github.com/VergeGroup/Verge">GitHub</a>! ⭐️',
      backgroundColor: '#fafbfc',  // Defaults to `#fff`.
      textColor: '#091E42',        // Defaults to `#000`.
    },
    colorMode: {defaultMode: 'dark'},
    image: 'img/ogimage2.png',
    googleAnalytics: {
      trackingID: 'UA-163893115-1',
      anonymizeIP: true,
    },
    prism: {
      additionalLanguages: ['swift'],
    },
    navbar: {
      title: 'Verge',
      logo: {
        alt: 'Verge Logo',
        src: 'img/sidebar-logo@2x.png',
      },
      items: [
        {
          to: 'docs/',
          activeBasePath: 'docs',
          label: 'Docs',
          position: 'left',
        },
        {
          to: 'docs/VergeStore/BasicUsage',
          activeBasePath: 'docs/VergeStore/BasicUsage',
          label: 'Basic usage',
          position: 'left',
        },
        {
          href: 'https://github.com/VergeGroup/Verge',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'More',
          items: [
            {
              label: 'GitHub',
              href: 'https://github.com/VergeGroup/Verge',
            },
          ],
        },
      ],
      copyright: `Copyright © ${
          new Date().getFullYear()} VergeGroup. Built with Docusaurus.`,
    },
  },
  presets: [
    [
      '@docusaurus/preset-classic',
      {
        docs: {
          // It is recommended to set document id as docs home page (`docs/`
          // path).
          sidebarPath: require.resolve('./sidebars.js'),
          editUrl: 'https://github.com/VergeGroup/Verge/docs',
        },
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
      },
    ],
  ],
};
