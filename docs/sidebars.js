/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  docsSidebar: [
    "intro",
    {
      type: "category",
      label: "Getting Started",
      collapsed: false,
      items: ["getting-started", "installation", "quick-start"],
    },
    {
      type: "category",
      label: "Guides",
      items: [
        "guides/clock-sync",
        "guides/weapon-profiles",
        "guides/scaled-avatars",
        "guides/anti-abuse",
        "guides/debugging",
      ],
    },
    {
      type: "category",
      label: "API Reference",
      items: [
        "api/rewind",
        "api/types",
        "api/config",
        "api/server",
        "api/client",
        "api/rig-adapter",
        "api/hitbox-profile",
        "api/clock-sync",
        "api/replication",
        "api/vehicles",
        "api/armor",
        "api/abuse-tracker",
        "api/movement-validator",
      ],
    },
  ],
};

export default sidebars;
