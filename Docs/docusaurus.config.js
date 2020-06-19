module.exports = {
  title: "Verge",
  tagline: "A performant flux library for iOS App - SwiftUI / UIKit",
  url: "https://vergegroup.github.io/Verge/",
  baseUrl: "",
  favicon: "img/favicon.ico",
  organizationName: "VergeGroup", // Usually your GitHub org/user name.
  projectName: "Verge", // Usually your repo name.
  themeConfig: {
    googleAnalytics: {
      trackingID: "UA-163893115-1",
      anonymizeIP: true,
    },
    prism: {
      additionalLanguages: ["swift"],
    },
    navbar: {
      title: "Verge",
      logo: {
        alt: "Verge Logo",
        src: "img/verge-logo.svg",
      },
      links: [{
          to: "docs/",
          activeBasePath: "docs",
          label: "Docs",
          position: "left",
        },
        {
          href: "https://github.com/VergeGroup/Verge",
          label: "GitHub",
          position: "right",
        },
      ],
    },
    footer: {
      style: "dark",
      links: [{
        title: "More",
        items: [{
          label: "GitHub",
          href: "https://github.com/VergeGroup/Verge",
        }, ],
      }, ],
      copyright: `Copyright © ${new Date().getFullYear()} Verge, Inc. Built with Docusaurus.`,
    },
  },
  presets: [
    [
      "@docusaurus/preset-classic",
      {
        docs: {
          // It is recommended to set document id as docs home page (`docs/` path).
          homePageId: "Overview",
          sidebarPath: require.resolve("./sidebars.js"),
          editUrl: "https://github.com/VergeGroup/Verge/docs",
        },
        theme: {
          customCss: require.resolve("./src/css/custom.css"),
        },
      },
    ],
  ],
};
