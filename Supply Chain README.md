
# 📦 Integrated Retail Decision Optimization  
**Pricing • Assortment • Inventory Planning**

---

## 📌 Project Overview

This project develops and implements an **integrated optimization framework** for retail decision-making that jointly determines:

- **Product assortment** (which products to offer),
- **Dynamic pricing** (prices across time),
- **Inventory ordering and holding decisions**,

over a **multi-period planning horizon**, while explicitly accounting for **customer heterogeneity, substitution behavior, and seasonality**.

Unlike traditional retail approaches that optimize these decisions independently, this project demonstrates that **joint optimization leads to significantly higher profitability and more robust decision-making**, especially in thin-margin retail environments.

---

## 🎯 Problem Statement

Retailers typically make pricing, assortment, and inventory decisions in silos. However:

- Pricing decisions affect demand and substitution.
- Assortment decisions affect customer choice.
- Inventory decisions affect feasibility, cost, and profitability.

Optimizing these decisions independently leads to **substantial profit loss**.

This project builds **mathematical optimization models** that integrate all three decisions into a **single decision-support system**.

---

## 👥 Customer Segmentation

### Why Segment Customers?

Customers differ in:
- Willingness to pay,
- Brand preferences,
- Sensitivity to price changes,
- Substitution behavior.

To capture this heterogeneity in a tractable way, customers are grouped into **6 distinct segments**.

### How Segments Are Created

Customer segments are inferred from **historical sales and pricing data**, based on:

- Observed switching behavior between products,
- Price sensitivity,
- Relative demand changes during promotions.

Each segment is characterized by:
- A **segment size**,
- **Reservation prices** for each product and time period,
- Distinct substitution patterns.

> These segments represent behavioral archetypes such as price-sensitive shoppers, brand-loyal customers, and quality-driven buyers.

---

## 🧠 Demand Model: Maximum Surplus Choice

This project uses a **deterministic maximum surplus choice model** to describe customer behavior.

### How It Works

For each customer segment *i*, product *j*, and period *t*:

```
Surplus_ijt = α_ijt − p_jt
```

Where:
- `α_ijt` is the **reservation price** (maximum willingness to pay),
- `p_jt` is the product price.

### Choice Rule

- Customers choose the product with the **highest non-negative surplus**.
- If all surpluses are negative, the customer does **not purchase**.

### Why This Model?

- Accurately captures **substitution behavior** in fast-moving consumer goods.
- Supported by empirical evidence from historical sales data.
- Enables **exact optimization** using mixed-integer programming.

---

## 📊 Data & Calibration

### Data Sources

- Historical weekly sales and pricing data from a retail category (FMCG-style).
- Synthetic data generated to test scalability and seasonal effects.

### Reservation Price Estimation

Reservation prices and segment sizes are **calibrated** using observed demand patterns.

A calibration model minimizes the error between:
- Observed demand,
- Demand predicted by the maximum-surplus model.

This allows segmentation and behavioral parameters to be inferred **using only aggregate sales data**.

---

## 📈 Hypothesis Testing & Behavioral Validation

Hypothesis testing is conducted to validate:

- Price sensitivity differences across segments,
- Substitution patterns during price changes,
- Stability of segment behavior over time.

Results confirm:
- Significant behavioral differences between segments,
- Strong alignment between predicted and observed switching behavior,
- Robustness of the maximum surplus assumption.

---

## 📆 Seasonality Modeling

The model explicitly incorporates **seasonality** in:

- Demand patterns,
- Procurement and operational costs.

### Impact

- Adjusts assortment breadth dynamically,
- Optimizes inventory ordering timing,
- Improves profitability by up to **40%** compared to static approaches.

---

## 🧮 Optimization Models

### APO-0: MINLP (Conceptual Model)
- Nonlinear formulation.
- Solved using global solvers for benchmarking.
- Not scalable for large instances.

### APO-1: Linearized MILP (Implemented Model)
- Exact linearization using auxiliary variables.
- Solved using **AMPL + CPLEX/Gurobi**.
- Scales to **50–100+ products** efficiently.

---

## 🧪 Benchmark Comparisons

| Policy | Description | Profit Impact |
|------|------------|---------------|
| ZIP | Zero inventory carried | −57% to −70% |
| BIP | All inventory ordered upfront | −32% to −55% |
| Margin-based | Top-margin products only | −13% to −15% |
| Integrated (This Work) | Joint optimization | **Best performance** |

---

## 📊 Results & Insights

- Optimal pricing and assortments do **not** follow simple heuristics.
- Inventory timing changes which products are profitable.
- Myopic policies destroy **30–70% of profit**.
- Seasonality is a **profit opportunity**.
- Integrated optimization consistently outperforms traditional approaches.

---

## ⏱ Planning Horizon

- Multi-period planning (e.g., **6–12 weekly periods**).
- Suitable for seasonal retail planning.
- Zero initial and final inventory assumptions.

---

## 🛠 Tools & Technologies

- **AMPL** (optimization modeling)
- **CPLEX / Gurobi** (MILP solvers)
- **Global solvers** (MINLP benchmarking)
- **Python / Jupyter** (data prep, calibration, hypothesis testing)

---

## 📁 Repository Structure

```
Integrated-Retail-Optimization/
├── README.md
├── ampl/
│   ├── ap0_minlp.mod
│   ├── ap1_linearized.mod
│   ├── sample.dat
├── data/
│   ├── historical_sales.csv
│   ├── synthetic_generator.py
├── analysis/
│   ├── segmentation_tests.ipynb
│   ├── hypothesis_testing.ipynb
├── results/
│   ├── profit_comparison.csv
│   └── plots/
└── references/
    └── Ghoniem_Maddah_2015.pdf
```

---

## 🧾 References

- Ghoniem, A., & Maddah, B. (2015). *Integrated retail decisions with multiple selling periods and customer segments: Optimization and insights*. **Omega**, 55, 38–52.

---

## ✅ Summary

This project demonstrates that **integrated, data-driven optimization** of pricing, assortment, and inventory decisions—grounded in realistic customer behavior and seasonality—dramatically outperforms traditional retail heuristics and provides a scalable framework for real-world decision support.
