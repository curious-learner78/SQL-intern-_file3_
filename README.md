# Database Optimization for Environmental Impact Analysis

## 📌 Project Overview
This repository contains the Week 3 submission for the **Virtual Sustainability SQL Development Internship**. It details advanced SQL performance tuning, diagnostic execution plan analysis (`EXPLAIN ANALYZE`), covering B-Tree indexing, declarative time-series range partitioning, and materialized view architectures designed for large-scale environmental telemetry datasets (50M+ rows).

---

## 🛠️ Optimization Techniques Implemented

1. **Sargable Predicate Refactoring:** Eliminated non-sargable functions (`EXTRACT()`) on indexed timestamp columns to enable Index Scans.
2. **Covering B-Tree Indexing:** Constructed composite B-Tree indexes with `INCLUDE` clauses to execute zero-heap-fetch **Index-Only Scans**.
3. **Declarative Range Partitioning:** Divided high-volume IoT transactional logs into year-based physical tables to leverage **Partition Pruning**.
4. **Materialized Views:** Pre-computed heavy annual corporate aggregations, providing sub-15ms dashboard load times.

---

## 📊 Performance Benchmarks Summary

| Phase | Optimization Strategy | Query Latency | Performance Gain |
| :--- | :--- | :--- | :--- |
| **Baseline** | Unoptimized Query | 42,350 ms | 1.0x (Baseline) |
| **Phase 1** | Refactored Sargable Predicates | 18,120 ms | 2.3x Faster |
| **Phase 2** | Composite Covering Index | 3,210 ms | 13.2x Faster |
| **Phase 3** | Declarative Range Partitioning | 840 ms | 50.4x Faster |
| **Phase 4** | Materialized View Pre-aggregation | 11.5 ms | 3,682.6x Faster |
