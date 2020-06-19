import React from "react";
import clsx from "clsx";
import Layout from "@theme/Layout";
import Link from "@docusaurus/Link";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import useBaseUrl from "@docusaurus/useBaseUrl";
import styles from "./styles.module.css";

const features = [
  {
    title: <>🛹 Small start unidirectional data flow</>,
    description: (
      <>
        Verge is designed for use from small and supports to scale. Setting
        Verge up quickly, and tune-up when we need it.
      </>
    ),
  },
  {
    title: <>🏎 Focus on performance</>,
    description: (
      <>
        Does flux have a good performance?
        <br /> The performance will be the worst depends on how it is used.
        <br />
        Verge automatically tune-up and shows us how we could gain a performant.
      </>
    ),
  },
  {
    title: (
      <>
        ⛱ Available on <b>UIKit</b> and <b>SwiftUI</b>
      </>
    ),
    description: (
      <>
        Verge supports both of UI framework. Especially, it highly supports to
        update partially UI on UIKit.
      </>
    ),
  },
];

function Feature({ imageUrl, title, description }) {
  const imgUrl = useBaseUrl(imageUrl);
  return (
    <div className={clsx("col col--4", styles.feature)}>
      {imgUrl && (
        <div className="text--center">
          <img className={styles.featureImage} src={imgUrl} alt={title} />{" "}
        </div>
      )}
      <h3> {title} </h3> <p> {description} </p>
    </div>
  );
}

function Home() {
  const context = useDocusaurusContext();
  const { siteConfig = {} } = context;
  return (
    <Layout
      title={`${siteConfig.title} - A state management library for iOS`}
      description="Description will go into a meta tag in <head />"
    >
      <header className={clsx("", styles.heroBanner)}>
        <div className="container">
          <h1 className="hero__title"> {siteConfig.title} </h1>{" "}
          <p className="hero__subtitle"> {siteConfig.tagline} </p>{" "}
          <div className={styles.buttons}>
            <Link
              className={clsx(
                "button button--outline button--secondary button--lg",
                styles.getStarted
              )}
              to={useBaseUrl("docs/")}
            >
              Get Started{" "}
            </Link>
          </div>
        </div>
      </header>
      <main>
        {features && features.length > 0 && (
          <section className={styles.features}>
            <div className="container">
              <div className="row">
                {features.map((props, idx) => (
                  <Feature key={idx} {...props} />
                ))}
              </div>
            </div>
          </section>
        )}
      </main>
    </Layout>
  );
}

export default Home;
