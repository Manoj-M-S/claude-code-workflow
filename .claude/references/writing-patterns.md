# QED42 Writing Patterns — Extracted from Case Studies

This file contains structural and stylistic patterns derived from QED42's published case
studies. These are the target patterns for all long-form QED42 content.

---

## Case Study Structure Pattern

The consistent structure across QED42 case studies:

```
1. Context (2–3 sentences) — who the client is and what their platform does for them
2. Problem setup — what was growing or changing that made the status quo unsustainable
3. Specific friction points — named, concrete, not abstract (e.g. "IPO pages took two
   weeks to go live", "stock widget wasn't indexable")
4. Decision/approach — how QED42 decided what to tackle first and why
5. Solutions — what was built, each with a plain explanation of why it was the right call
6. Outcome — metrics first, then operational change, then what's now possible
```

---

## Opening patterns (study these)

**Start with what the platform does for the business:**

> "Kotak Securities is one of India's largest stock broking firms, serving retail and
> institutional investors across equity, derivatives, and currency markets. Their public
> platform is a pre-login informational portal where prospective investors come to learn
> about products..."

**Start with the tension between growth and capability:**

> "As that audience grew, so did the demand on the platform: faster publishing, more
> content types, and infrastructure that could handle the traffic without slowing down."

**Start with the constraint, not the solution:**

> "Like most premium hospitality brands entering the direct-booking space, Banyan Living
> faced a structural challenge: the off-the-shelf tools available for short-term rental
> management are built for listings at scale, not for brands with a distinct voice."

**NEVER start with:**

- "In today's digital landscape..."
- "As [company] looked to grow..."
- "[Company] needed a partner who could..."
- A list of services delivered

---

## How QED42 describes its approach

The approach section is honest about constraints and explains decisions:

> "Fixing everything at once on a platform this size wasn't an option. The portal served a
> large daily audience, and any disruption would be immediately visible. The decision was
> to work section by section, resolving the constraints that were causing the most
> friction first."

> "Technical choices were made around what the team could own and extend over time, not
> just what would work for the build."

Key patterns:

- Name what was NOT done and why
- Explain the logic behind sequencing decisions
- Show that choices were made around the client's operational reality, not just technical
  preference
- Emphasise client ownership as a goal, not just a side effect

---

## How outcomes are written

Outcomes are specific, quantified where possible, and framed in operational terms:

**Good:**

> "Frontend effort is down by over 40%. The infrastructure handles over 500,000 daily
> visitors without latency or downtime."

> "IPO content that took two weeks to publish takes days. Platform changes that took days
> take hours."

> "Direct reservations grew 580% in five months."

> "Over 18 months it reduced frontend effort by over 40% and brought release cycles from
> days to hours."

**The pattern:**

- Metric first (number, percentage, time comparison)
- What changed operationally
- What's now possible that wasn't before

**Not:**

> "The platform now performs significantly better and the team is more efficient."
> "QED42 helped Kotak Securities achieve their digital transformation goals."

---

## How QED42 describes technical decisions

Technical decisions are explained in terms of what problem they solved, not just what they
are:

> "The third-party stock widget was replaced with a custom API module built around Kotak
> Securities' content schema. The old widget wasn't indexable and added no search value.
> The new one updates in near real time, ranks for high-volume stock keywords, and turned
> a feature that previously contributed nothing to search into a consistent source of
> organic acquisition."

Pattern:

1. What was replaced / what changed
2. What was wrong with the old approach (plainly stated)
3. What the new approach does
4. What result it created

---

## Vocabulary QED42 uses naturally

These words and phrases appear in QED42's writing and feel authentic:

- "platform ownership"
- "editorial workflow"
- "publishing velocity" / "publish without raising a development request"
- "progressive rebuild"
- "vendor dependency" / "vendor FTP uploads"
- "content governance"
- "headless architecture" / "decoupled build"
- "composable"
- "search visibility" / "indexable"
- "operational reality"
- "release cycles"
- "business-critical"
- "modular templates"
- "design system"
- "handoff" (as in: each section was handed back before the next began)
- "internal ownership"
- "without disrupting"
- "performance targets"
- "Core Web Vitals"
- "multilingual delivery"

---

## Paragraph rhythm

QED42 writes in short, declarative paragraphs. Most paragraphs are 2–4 sentences. The
rhythm is:

- Statement of fact or situation
- Implication or why it matters
- (Optional) what was done about it

Example:

> "The on-premise setup was replaced with a cloud infrastructure built for the traffic
> volumes the platform was already carrying. Autoscaling and regional failover removed
> the risk of performance degradation during high traffic periods. The platform now
> handles peak load without intervention."

Not:

> "As part of our comprehensive cloud migration strategy, we worked closely with the
> Kotak Securities team to evaluate their infrastructure needs and develop a tailored
> solution that would not only address their immediate performance challenges but also
> provide a scalable foundation for future growth."

---

## Proof point bank (cite these in drafts when relevant)

| Client              | Metric                                                                | Context                                     |
| ------------------- | --------------------------------------------------------------------- | ------------------------------------------- |
| Kotak Securities    | 500,000+ daily visitors                                               | Finance portal, India                       |
| Kotak Securities    | 40%+ reduction in frontend effort                                     | Over 18 months, design system               |
| Kotak Securities    | Release cycles: days → hours                                          | After design system implementation          |
| Kotak Securities    | IPO publishing: 2 weeks → days                                        | Dedicated internal workflow                 |
| Banyan Living       | 580% growth in direct reservations                                    | 5 months post-launch                        |
| Laaha (UN)          | 12 countries, 14 languages                                            | Platform for women in humanitarian settings |
| QED42 community     | 170+ contributions                                                    | Drupal community contributions              |
| JavaScript projects | 20–30% shorter release cycles                                         | GenAI-assisted engineering                  |
| JavaScript projects | Lighthouse/Core Web Vitals >80 mobile                                 | Performance benchmark                       |
| UN partnership      | 5 years                                                               | Across multiple UN agencies                 |
| Client portfolio    | Nestlé, Stanford, Canon, Fila, L'Oréal, HP Inc., Novartis, Sony, OECD | Enterprise and mission-driven               |
