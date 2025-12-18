// @ts-check
import { themes as prismThemes } from "prism-react-renderer";

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: "Rewind",
  tagline: "Server-side lag compensation for Roblox",
  favicon: "img/favicon.svg",

  url: "https://text21.github.io",
  baseUrl: "/Rewind/",

  organizationName: "text21",
  projectName: "Rewind",

  onBrokenLinks: "throw",
  onBrokenMarkdownLinks: "warn",

  i18n: {
    defaultLocale: "en",
    locales: ["en"],
  },

  presets: [
    [
      "classic",
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: "./sidebars.js",
          editUrl: "https://github.com/text21/Rewind/tree/main/docs/",
        },
        blog: false,
        theme: {
          customCss: "./src/css/custom.css",
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      image: "img/rewind-social-card.png",
      navbar: {
        title: "Rewind",
        logo: {
          alt: "Rewind Logo",
          src: "img/Logo.png",
        },
        items: [
          {
            type: "docSidebar",
            sidebarId: "docsSidebar",
            position: "left",
            label: "Docs",
          },
          {
            to: "/docs/api/rewind",
            label: "API",
            position: "left",
          },
          {
            to: "/changelog",
            label: "Changelog",
            position: "left",
          },
          {
            href: "https://github.com/text21/Rewind",
            label: "GitHub",
            position: "right",
          },
        ],
      },
      footer: {
        style: "dark",
        links: [
          {
            title: "Docs",
            items: [
              {
                label: "Getting Started",
                to: "/docs/getting-started",
              },
              {
                label: "API Reference",
                to: "/docs/api/rewind",
              },
            ],
          },
          {
            title: "Community",
            items: [
              {
                label: "Discord",
                href: "#",
              },
              {
                label: "DevForum",
                href: "#",
              },
            ],
          },
          {
            title: "More",
            items: [
              {
                label: "GitHub",
                href: "https://github.com/text21/Rewind",
              },
              {
                label: "Changelog",
                to: "/changelog",
              },
            ],
          },
        ],
        copyright: `Copyright © ${new Date().getFullYear()} Rewind. Built with Docusaurus.`,
      },
      prism: {
        theme: prismThemes.github,
        darkTheme: prismThemes.dracula,
        additionalLanguages: ["lua"],
      },
      colorMode: {
        defaultMode: "dark",
        disableSwitch: false,
        respectPrefersColorScheme: true,
      },
    }),
};

export default config;
