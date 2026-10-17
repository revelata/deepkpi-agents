---
name: industry-classification
description: >
  Classifies a US public company into one of the three industries the
  operating-model skill supports — restaurant, retail, software — or returns
  UNSUPPORTED. Invoked by the `operating-model` orchestrator (its Step 1.2)
  right after the company is resolved and before any workbook is created or
  any KPI inventory is pulled. Makes exactly one deepKPI call,
  `get_company_summary`, applies the criteria below in fixed precedence, and
  hands back the industry with a one-line basis. Both the revenue router and
  the costs router consume that determination; neither re-classifies.
---

# industry-classification

This sub-skill is part of the `operating-model` system. It owns **one decision,
made once**: which of the supported industries the company belongs to. The
orchestrator invokes it at Step 1.2 and passes the result to the `revenue` and
`costs` routers, so revenue and costs can never disagree about what the company
is, and a company the skill cannot model is turned away **before** a scaffold is
written or `list_kpis` is run.

**Supported industries:** **restaurant**, **retail**, **software / technology**.
Everything else is **unsupported**. There is no generic fallback build: an
unsupported company stops at the orchestrator with a plain statement of what the
skill models today.

**Inputs expected from the orchestrator:** the resolved `company_id` and the
official company name.

**Data source:** deepKPI only — see `../../_common/data-source-rules.md`. On
failure, follow `../../_common/connection-failure.md`. This skill's only call is
`get_company_summary`.

## Step 1 — Read the business description

Call **`get_company_summary`** with the resolved `company_id` to retrieve the
narrative business description from the company's latest 10-K. Read it in full
before applying the criteria. The summary is the **only** evidence at this step:
the KPI inventory has not been pulled yet (orchestrator Step 3), and the
criteria below are decided from the business description alone.

## Step 2 — Apply the criteria, in precedence order

### Restaurant

A company counts as a **restaurant** when its primary business is operating and/or
franchising eating establishments — full-service or quick-service restaurants,
cafes, fast-casual concepts, bars, or similar food-service venues where prepared
food and beverages sold to consumers are the core revenue driver. Signals to look
for in the summary:

- Language describing **restaurants, eateries, dining, food service, menu,
  quick-service / fast-casual / full-service, franchised or company-operated
  units, guests / traffic**.
- Operating KPIs typical of the vertical: **same-store / comparable sales, average
  unit volume (AUV), restaurant count / openings / closures, restaurant-level
  margin, check size / average ticket**.

Use judgment for **diversified or multi-brand parents**: if restaurants are the
dominant segment (e.g. a multi-concept restaurant group), route to restaurants.
If food service is only a minor segment of a broader company, the company is
**not a restaurant** — test retail and software next. When the summary is
genuinely ambiguous, briefly state your read and ask the user to confirm the
industry before returning.

### Retail

A company counts as **retail** when its primary business is selling physical
merchandise to consumers — through its own stores, its own e-commerce channel, or
wholesale into other retailers' shelves. This is deliberately **broad** and covers
both **store-based retailers** (the buy-it-and-resell-it model) and **branded
consumer-products companies** whose economics are driven by units sold, price per
unit, and their own retail footprint. Merchandise categories include apparel,
footwear and accessories, groceries and consumables, general merchandise,
household goods, beauty, home improvement, electronics, sporting goods, auto
parts, and similar. The following buckets (with representative public companies)
illustrate the scope:

- **Mass, club & discount** — Walmart, Costco, Target, BJ's Wholesale, Dollar
  General, Dollar Tree, Ollie's Bargain Outlet, Five Below.
- **Grocery & consumables** — Kroger, Albertsons, Sprouts Farmers Market, Casey's
  (merchandise-led convenience), Grocery Outlet.
- **Apparel & footwear retail** — TJX, Ross Stores, Burlington, Gap, Abercrombie
  & Fitch, American Eagle, Urban Outfitters, Nordstrom, Dick's Sporting Goods,
  Foot Locker.
- **Branded apparel & footwear** — Nike, Crocs, Deckers, Skechers, On Holding,
  Ralph Lauren, Levi Strauss, Under Armour, Columbia Sportswear.
- **Specialty & beauty** — Ulta Beauty, Bath & Body Works, e.l.f. Beauty,
  Williams-Sonoma, RH, Tractor Supply, Academy Sports, Best Buy.
- **Home improvement & hardline** — Home Depot, Lowe's, Floor & Decor,
  AutoZone, O'Reilly Automotive, Advance Auto Parts.
- **E-commerce / DTC merchants that own inventory** — Chewy, Wayfair, Warby
  Parker, Revolve, Carvana.

Signals to look for in the summary:

- Language describing **retail stores, store base / fleet, merchandise,
  merchandising, assortment, SKUs, apparel, footwear, grocery, consumables,
  general merchandise, brands / branded products, wholesale and direct-to-consumer
  (DTC) channels, omnichannel, e-commerce / digital sales, membership or club
  fees, square footage, distribution centers, inventory and inventory turns,
  shrink, markdowns, private label**.
- Operating KPIs typical of the vertical: **store count / openings / closures,
  comparable-store or same-store sales, sales per square foot, gross square
  footage / selling square footage, average unit retail (AUR) or average selling
  price (ASP), units sold / pairs sold, transactions / traffic and average
  ticket / basket, e-commerce or digital penetration, wholesale vs. DTC revenue
  mix, membership fee income and renewal rates, revenue by merchandise category
  or geography, inventory turnover**.

Use judgment on the following edge cases:

- **Restaurants are not retail.** A company selling prepared food and beverages
  for consumption routes to restaurants (evaluated first, see Precedence). A
  retailer with in-store food service (e.g. a club or grocery chain with a food
  court) is still **retail**.
- **Marketplaces and platforms that do not own inventory** — eBay, Etsy, Uber,
  DoorDash, Airbnb — are **software**, not retail: they facilitate third-party
  transactions and are modeled on GMV × take rate. A first-party merchant that
  buys, holds, and sells its own inventory is **retail** even when it sells
  entirely online.
- **Branded consumer-products companies** (Crocs, Nike, e.l.f.) are retail when
  merchandise units and price per unit drive revenue, even where wholesale is
  the dominant channel. A **packaged-food, beverage, or household-products
  manufacturer** that sells only through third parties and reports no retail
  footprint or unit economics (e.g. a pure CPG bottler or ingredient supplier) is
  **unsupported**.
- **Convenience-store and fuel retailers** split on what carries the business:
  merchandise-led (Casey's) is **retail**; fuel-led (Murphy USA, Sunoco LP) is
  **unsupported**.
- **Auto dealers, pharmacies, and distributors** — franchised vehicle dealers
  (AutoNation, Lithia) and drug retail (Walgreens) are **retail** when store-level
  merchandise sales drive revenue; a pure **wholesale distributor** selling to
  businesses rather than consumers (McKesson, Sysco) is **unsupported**.

For **diversified parents**, route to retail when merchandise sales through
stores, DTC, or wholesale are the dominant revenue driver. When the summary is
genuinely ambiguous, briefly state your read and ask the user to confirm the
industry before returning.

### Software / technology

A company counts as **software** when its primary business is building,
distributing, or monetizing software, digital platforms, or internet services —
whether sold as subscriptions, transactions, usage, licenses, advertising, or
in-app spend. This is deliberately **broad**: a company does **not** need to be a
pure-play SaaS name to qualify. It captures the full technology-in-a-software
sense — enterprise and vertical SaaS, cybersecurity, data / infrastructure
software, consumer internet, online marketplaces and platforms, fintech software,
adtech / marketing software, gaming / interactive software, and AI software. The
following buckets (with representative public companies) illustrate the scope:

- **Enterprise SaaS** — ServiceNow, Salesforce, Workday, Monday.com, HubSpot.
- **Cybersecurity** — CrowdStrike, Palo Alto Networks, Zscaler, Okta.
- **Data / infrastructure** — Snowflake, Datadog, MongoDB, Cloudflare, Confluent.
- **Consumer internet** — Meta, Snap, Pinterest, Reddit, Spotify.
- **Marketplaces / platforms** — Uber, DoorDash, Airbnb, eBay, Etsy.
- **Fintech software** — Block, PayPal, Intuit, Fiserv, Toast.
- **Vertical software** — Veeva, Procore, Guidewire, AppFolio, nCino.
- **Adtech / marketing software** — The Trade Desk, AppLovin, DoubleVerify,
  Klaviyo, Braze.
- **Gaming / interactive software** — Roblox, Unity, Take-Two, Electronic Arts.
- **AI software** — Palantir, C3.ai, Tempus AI, SoundHound AI.

Signals to look for in the summary:

- Language describing **software, platform, cloud, SaaS, subscription, application,
  API, digital, internet, online marketplace, network, users / members,
  advertising, licenses**.
- Operating KPIs typical of the vertical: **ARR / ACV / bookings, subscription vs.
  transaction revenue, seats / paying users / subscribers, MAU / DAU, net revenue
  retention (NRR) / dollar-based net retention, gross merchandise value (GMV) /
  bookings, take rate, ARPU, churn, remaining performance obligations (RPO)**.

Use judgment for **diversified parents**: if software / digital platforms /
internet services are the dominant revenue driver, route to software. A company
whose core is hardware, semiconductors, physical goods, or services with only an
incidental software component is **not** software — it is **unsupported**. When
the summary is genuinely ambiguous, briefly state your read and ask the user to
confirm the industry before returning.

**Software only — the revenue model (a second determination, from the same
summary).** The software revenue router needs one more fact about the nature of
the business that the KPI inventory cannot supply, and this is the only step that
reads the description, so decide it here. Classify how the company earns its
revenue:

- **`platform`** — the company intermediates transactions between other parties
  and recognizes revenue as a **slice of the volume** that passes through it: a
  marketplace, a ride-hail or delivery network, a payments processor, an app
  store. The description speaks of gross bookings, gross merchandise or payment
  volume, take rate, sellers and buyers, drivers and riders. Uber, DoorDash,
  Airbnb, eBay, Etsy, Block.
- **`subscription`** — revenue is recurring fees for access to software or a
  service: SaaS, security, data and infrastructure, consumer subscriptions.
  ServiceNow, CrowdStrike, Snowflake, Dropbox, Spotify.
- **`advertising`** — revenue is sold against an audience's attention; the
  audience does not pay. Meta, Snap, Pinterest, Reddit.
- **`mixed`** — no single model is dominant, or the summary does not say (state
  which).

A software company that also reports contract **bookings** or **billings** (the
value of contracts signed) is **not** a platform on that account — those are
sales metrics on the scale of revenue, not intermediated volume. The distinction
is the nature of the revenue, read from the description, never from the size of a
series. When the model is genuinely ambiguous, state your read and ask the user
to confirm it before returning.

### Precedence

Evaluate **restaurant first, then retail, then software**. A company matches at
most one bucket; the first bucket it clearly fits wins. Anything that fits none
of the three is **unsupported** — return that outcome (Step 3) and the
orchestrator stops. There is no generic fallback build.

A note on the restaurant-before-retail order: food-service concepts that also sell
packaged goods (a coffee chain selling bagged beans, a bakery-cafe selling
retail-packaged product) are **restaurants** — they match first and stop there.
Conversely, a grocer, club, or mass retailer with prepared-food counters is
**retail**, because prepared food is incidental to the merchandise business.

A note on the retail-before-software order: a first-party merchant that owns
inventory is **retail** even when it sells entirely online (Chewy, Wayfair,
Carvana) — it matches retail first and stops there. An asset-light **marketplace
or platform** that never takes title to the goods and earns a take rate on
third-party transactions (eBay, Etsy, DoorDash) is **software**, since the
merchandise is not its own. A retailer's e-commerce app or loyalty platform does
not make it software.

## Step 3 — Hand back to the orchestrator

Return exactly one of:

- **`industry: restaurant | retail | software`** plus a **one-line basis** citing
  the summary signal that decided it — and, for software, **`revenue model:
  platform | subscription | advertising | mixed`** with its own one-line basis; or
- **`UNSUPPORTED — <one-line basis>`**, naming what the company's primary business
  is and which bucket it came closest to and why it did not fit.

Where the summary was ambiguous, the user has already confirmed the industry
(Step 2) — say so in the basis. Do not write to any workbook; this skill produces
a determination, not rows.

## Notes

- `get_company_summary` is the **only** deepKPI call this skill makes, and the
  orchestrator makes it exactly once per build. Do not re-run `query_company_id`,
  and do not run `list_kpis` here — the inventory is the orchestrator's Step 3.
- **Adding an industry** means four things, all of them: a criterion and
  precedence position in this file, a revenue build under `../revenue/`, a cost
  build under `../costs/`, and a net-working-capital driver map under
  `../net-working-capital/`. Until all four exist the industry stays unsupported.
