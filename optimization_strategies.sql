-- =============================================================================
-- Database Optimization Strategies for Sustainability Data Analysis
-- Internship Task: Week 3 - Database Optimization for Environmental Impact Analysis
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. UNOPTIMIZED BASELINE QUERY (Causes Full Table Scan)
-- -----------------------------------------------------------------------------
-- Problem: EXTRACT() function prevents index usage on reading_date column
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    f.facility_name,
    SUM(e.consumption_kwh) AS total_kwh
FROM energy_consumption e
JOIN facilities f ON e.facility_id = f.facility_id
WHERE EXTRACT(YEAR FROM e.reading_date) = 2026
  AND e.energy_type = 'Electricity'
GROUP BY f.facility_name;


-- -----------------------------------------------------------------------------
-- 2. PHASE 1 OPTIMIZATION: REFACTORED SARGABLE QUERY
-- -----------------------------------------------------------------------------
-- Solution: Replace function call with explicit date range bounds
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    f.facility_name,
    SUM(e.consumption_kwh) AS total_kwh
FROM energy_consumption e
JOIN facilities f ON e.facility_id = f.facility_id
WHERE e.reading_date >= '2026-01-01' AND e.reading_date < '2027-01-01'
  AND e.energy_type = 'Electricity'
GROUP BY f.facility_name;


-- -----------------------------------------------------------------------------
-- 3. PHASE 2 OPTIMIZATION: COMPOSITE COVERING INDEX
-- -----------------------------------------------------------------------------
-- Solution: Index filters and include payload metrics for Index-Only Scans
CREATE INDEX IF NOT EXISTS idx_energy_opt_covering 
ON energy_consumption (reading_date, energy_type, facility_id) 
INCLUDE (consumption_kwh);


-- -----------------------------------------------------------------------------
-- 4. PHASE 3 OPTIMIZATION: DECLARATIVE RANGE PARTITIONING
-- -----------------------------------------------------------------------------
-- Solution: Partition massive time-series logs by calendar year
CREATE TABLE IF NOT EXISTS energy_consumption_partitioned (
    energy_id BIGSERIAL,
    facility_id INT NOT NULL,
    energy_type VARCHAR(30) NOT NULL,
    consumption_kwh NUMERIC(12, 2) NOT NULL,
    reading_date DATE NOT NULL
) PARTITION BY RANGE (reading_date);

-- Yearly child partitions
CREATE TABLE IF NOT EXISTS energy_consumption_y2025 PARTITION OF energy_consumption_partitioned
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE TABLE IF NOT EXISTS energy_consumption_y2026 PARTITION OF energy_consumption_partitioned
    FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');


-- -----------------------------------------------------------------------------
-- 5. PHASE 4 OPTIMIZATION: MATERIALIZED VIEWS FOR EXECUTIVE REPORTING
-- -----------------------------------------------------------------------------
-- Solution: Pre-aggregate heavy annual aggregations for instant dashboard loads
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_facility_yearly_sustainability AS
SELECT 
    f.facility_id,
    f.facility_name,
    f.country,
    DATE_TRUNC('year', e.reading_date) AS reporting_year,
    SUM(e.consumption_kwh) AS annual_energy_kwh,
    COUNT(e.energy_id) AS total_readings
FROM facilities f
JOIN energy_consumption e ON f.facility_id = e.facility_id
GROUP BY f.facility_id, f.facility_name, f.country, DATE_TRUNC('year', e.reading_date);

-- Unique index required for concurrent non-blocking refreshes
CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_facility_year 
ON mv_facility_yearly_sustainability (facility_id, reporting_year);

-- Command to refresh view asynchronously:
-- REFRESH MATERIALIZED VIEW CONCURRENTLY mv_facility_yearly_sustainability;
