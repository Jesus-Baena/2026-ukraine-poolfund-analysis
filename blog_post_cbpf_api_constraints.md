# The Hidden Constraints of Humanitarian Data: Lessons from the CBPF API

## Introduction
In our recent initiative to analyze the flow of Ukraine pooled funds, we turned to the Country-based Pooled Funds (CBPF) Data Services as our primary source of truth. The goal was straightforward: to build an automated pipeline that tracks donor contributions against allocated projects, providing a clear picture of how funds are distributed in the crisis response. However, what began as a standard data engineering task quickly revealed the friction between data availability and data usability in the humanitarian sector.

## The Good: Transparency at a Glance
It is important to acknowledge where the system succeeds. The transparency of the data is commendable. Through the CBPF API and data exports, we have access to granular details that are often obscured in other sectors. We can see:
*   **Detailed Project Information**: Project titles, sectors, and objectives are readily available.
*   **Financials**: Budget totals and approved amounts are transparent.
*   **Partnerships**: The names of implementing partners are clear, allowing us to see who is doing the work on the ground.

This level of disclosure is vital for accountability and provides a solid foundation for high-level reporting.

## The Bad: API Limitations
While the data exists, accessing it programmatically exposes significant reliability issues.
*   **Reliability**: The strict dependence on the `AllocationFlow` endpoint for detailed financial tracking hit a wall. We consistently encountered HTTP 500 Internal Server Errors errors. Crucially, these weren't transient network glitches but seemingly structural failures when querying specific date ranges or parameters, breaking our automated pipelines.
*   **Format Inconsistency**: In modern API design, errors should be returned as structured JSON. The CBPF API frequently returns HTML error pages instead of proper status codes or JSON messages. This breaks parsers and requires brittle error handling logic to distinguish between data and a generic "Something went wrong" webpage.
*   **Field Ambiguity**: The schema lacks clear documentation regarding identifier fields. Navigating the relationship between `ChfId`, `ChfProjectCode`, and `PartnerCode` required trial-and-error reverse engineering rather than following a specification.

## The Ugly: Analysis Blockers
Beyond technical glitches, there are structural constraints that limit the depth of analysis.
*   **The Traceability Gap**: This is arguably a feature of "pooled" funds, but it presents an analytical blocker. You can track money *in* (via the `Contributions` endpoint) and money *allocated* (via `ProjectSummary`). However, the pooling mechanism means you cannot trace a specific donor's dollar to a specific project. We can report on aggregate flows, but not direct lineage.
*   **Missing Flow Data**: Because the `AllocationFlow` endpoint is unreliable, we were forced to reconstruct partner-type analysis (INGO vs. NNGO) manually using the `ProjectSummary` endpoint. This workaround relies on `OrganizationType` fields being consistent across thousands of records, introducing a margin of error that shouldn't exist.
*   **Granularity**: Budget data often arrives as a single integer. We lack the ability to analyze administrative versus operational costs *over time* or by activity. We see the total price tag, but not the receipt.
*   **Historical Blind Spots (The Pipeline Problem)**: The API provides a snapshot of the current moment, but not a historical ledger of the project lifecycle. This is most critical in the `Pipeline` endpoints, which show projects currently under review or development. Once a project is approved or rejected, it effectively vanishes from this view. Unless you build your own daily archiving system (as we are doing), it is impossible to analyze approval bottlenecks, rejection rates, or the "time-to-decision" for critical funding. The API deletes the history as it creates the future.
*   **The Narrative Black Hole**: While the quantitative endpoints exist, the qualitative data—full project proposals, detailed monitoring reports, and narrative justifications beyond a tweet-length summary—remain out of reach. This effectively blocks any possibility of leveraging Large Language Models (LLMs) to analyze project logic, methodology, or impact stories at scale. We are left with the numbers but lose the context, making it impossible to audit *how* the work is being done or to detect patterns in project quality.

## Technical Debt in Automation
Integrating this data into modern workflows (like n8n) highlighted further friction. The API's structure necessitated complex handling in our database layer. We struggled with PostgreSQL transaction blocks and dynamic table handling because the API schema doesn't always map cleanly to normalized relational tables. We had to build robust—and heavy—logic just to handle the unpredictability of the incoming data structure.

## Conclusion
The CBPF API allows for a commendable high-level overview of humanitarian financing in Ukraine. We can say *how much* money is moving and *roughly* where it is going. However, the technical limitations—reliability issues, inconsistent error handling, and data granularity—prevent forensic-level audit or real-time flow analysis. For now, the "data revolution" in this specific niche remains a mix of manual workarounds and automated hopes.
