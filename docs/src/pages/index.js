import clsx from "clsx";
import Link from "@docusaurus/Link";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Layout from "@theme/Layout";
import Heading from "@theme/Heading";

import styles from "./index.module.css";

function HeroBanner() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <header className={clsx("hero hero--dark hero-glow", styles.heroBanner)}>
      <div className="container">
        <div className={styles.heroLogo}>⏪</div>
        <Heading as="h1" className="hero__title">
          {siteConfig.title}
        </Heading>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <p className={styles.heroDescription}>
          A powerful, production-ready lag compensation framework for Roblox
          games. Handle hit validation, projectile traces, and melee attacks
          with server-authoritative precision.
        </p>
        <div className={styles.buttons}>
          <Link
            className="button button--primary button--lg"
            to="/docs/getting-started"
          >
            Get Started →
          </Link>
          <Link
            className="button button--secondary button--lg"
            to="/docs/api/rewind"
          >
            API Reference
          </Link>
        </div>
        <div className={styles.installCmd}>
          <code>Rewind = "text21/rewind@1.0.0"</code>
        </div>
      </div>
    </header>
  );
}

const features = [
  {
    title: "Server-Authoritative",
    icon: "🛡️",
    description:
      "All hit validation happens on the server. Never trust the client. Built-in anti-abuse with duplicate detection, distance sanity checks, and rate limiting.",
  },
  {
    title: "Lag Compensation",
    icon: "⏰",
    description:
      "Automatically rewind player positions to match what the attacker saw at shot time. Synced clocks ensure accurate timestamp reconciliation.",
  },
  {
    title: "Multi-Mode Validation",
    icon: "🎯",
    description:
      "Support for raycast weapons, projectile traces, capsule sweeps, and melee attacks. Configure per-weapon profiles with custom parameters.",
  },
  {
    title: "R6 & R15 Support",
    icon: "🤖",
    description:
      "Automatic rig detection with built-in hitbox profiles for both character types. Easily extend with custom profiles.",
  },
  {
    title: "Scaled Avatars",
    icon: "📏",
    description:
      "Full support for scaled avatars. Hitboxes automatically adjust based on character scale. Per-weapon scale multipliers available.",
  },
  {
    title: "Debug Tools",
    icon: "🔧",
    description:
      "Built-in Iris debug panel for real-time visualization of hitboxes, shot traces, and performance stats. Toggle on/off in-game.",
  },
];

function FeatureCard({ title, icon, description }) {
  return (
    <div className={clsx("col col--4", styles.featureCol)}>
      <div className="feature-card">
        <div className="feature-icon">{icon}</div>
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

function FeaturesSection() {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className={styles.sectionHeader}>
          <Heading as="h2">Why Rewind?</Heading>
          <p>Everything you need for production-ready hit validation</p>
        </div>
        <div className="row">
          {features.map((props, idx) => (
            <FeatureCard key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}

function CodeExample() {
  return (
    <section className={styles.codeSection}>
      <div className="container">
        <div className="row">
          <div className="col col--6">
            <Heading as="h2">Simple API</Heading>
            <p>
              Get started with just a few lines of code. Rewind handles all the
              complexity of lag compensation, leaving you with a clean
              validation interface.
            </p>
            <ul className={styles.checkList}>
              <li>✓ High-level Validate() API</li>
              <li>✓ Per-weapon configuration</li>
              <li>✓ Automatic rig detection</li>
              <li>✓ Built-in type definitions</li>
            </ul>
          </div>
          <div className="col col--6">
            <pre className={styles.codeBlock}>
              {`-- Server-side hit validation
local Rewind = require(ReplicatedStorage.Rewind)

-- Validate a raycast hit
local result = Rewind.Validate(player, "Raycast", {
    origin = origin,
    direction = direction,
    targetIds = { targetPlayer.UserId },
    weaponId = "Rifle",
    timestamp = timestamp,
})

if result.accepted then
    -- Apply damage to result.victims
end`}
            </pre>
          </div>
        </div>
      </div>
    </section>
  );
}

export default function Home() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <Layout
      title={`${siteConfig.title} - Lag Compensation for Roblox`}
      description="Server-side lag compensation framework for Roblox games. Handle hit validation with precision."
    >
      <HeroBanner />
      <main>
        <FeaturesSection />
        <CodeExample />
      </main>
    </Layout>
  );
}
