-- ============================================================
-- Dental Clinic Operations Database — Analysis
-- Each query answers one operational question a practice
-- manager would actually ask.
-- ============================================================


-- ------------------------------------------------------------
-- Q1. What proportion of scheduled appointments are not completed?
-- ------------------------------------------------------------
SELECT
    status,
    COUNT(*) AS appointment_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM appointments), 1) AS percentage
FROM appointments
GROUP BY status
ORDER BY appointment_count DESC;


-- ------------------------------------------------------------
-- Q2. What kind of work does the practice do most of?
--     Establishes the case mix before comparing rates.
-- ------------------------------------------------------------
SELECT
    appointment_type,
    COUNT(*) AS appointment_count
FROM appointments
GROUP BY appointment_type
ORDER BY appointment_count DESC;


-- ------------------------------------------------------------
-- Q3. Which appointment types are most likely to break?
--     Conditional counting: SUM(CASE WHEN ...) counts a subset
--     inside the same GROUP BY that counts the total, so the
--     denominator survives. A WHERE clause would remove it.
-- ------------------------------------------------------------
SELECT
    appointment_type,
    COUNT(*) AS total_booked,
    SUM(CASE WHEN status = 'No-show' THEN 1 ELSE 0 END) AS no_shows,
    ROUND(SUM(CASE WHEN status = 'No-show' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS no_show_rate
FROM appointments
GROUP BY appointment_type
ORDER BY no_show_rate DESC;


-- ------------------------------------------------------------
-- Q4. Do no-show rates differ by provider?
--     Read alongside Q3 — see README on confounding.
-- ------------------------------------------------------------
SELECT
    pr.provider_name,
    pr.role,
    COUNT(*) AS total_booked,
    SUM(CASE WHEN a.status = 'No-show' THEN 1 ELSE 0 END) AS no_shows,
    ROUND(SUM(CASE WHEN a.status = 'No-show' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS no_show_rate
FROM appointments a
JOIN providers pr ON a.provider_id = pr.provider_id
GROUP BY pr.provider_name, pr.role
ORDER BY no_show_rate DESC;


-- ------------------------------------------------------------
-- Q5. Which procedures generate the most revenue?
--     Volume and revenue are not the same thing.
-- ------------------------------------------------------------
SELECT
    pc.procedure_code,
    pc.procedure_name,
    COUNT(*) AS times_performed,
    pc.fee AS unit_fee,
    ROUND(SUM(pc.fee), 2) AS total_revenue
FROM procedures pc
JOIN appointments a ON pc.appointment_id = a.appointment_id
GROUP BY pc.procedure_code, pc.procedure_name, pc.fee
ORDER BY total_revenue DESC;


-- ------------------------------------------------------------
-- Q6. What is the estimated revenue lost to broken appointments?
--     COUNT(DISTINCT appointment_id) is required: one visit can
--     carry several procedure rows, so a plain COUNT(*) would
--     inflate the denominator and understate visit value.
-- ------------------------------------------------------------
WITH avg_value AS (
    SELECT ROUND(SUM(pc.fee) * 1.0 / COUNT(DISTINCT a.appointment_id), 2) AS avg_per_visit
    FROM procedures pc
    JOIN appointments a ON pc.appointment_id = a.appointment_id
)
SELECT
    a.status,
    COUNT(*) AS appointments,
    (SELECT avg_per_visit FROM avg_value) AS avg_visit_value,
    ROUND(COUNT(*) * (SELECT avg_per_visit FROM avg_value), 2) AS estimated_lost_revenue
FROM appointments a
WHERE a.status IN ('No-show', 'Cancelled')
GROUP BY a.status;


-- ------------------------------------------------------------
-- Q7. Which patients are overdue for recall and should be called?
--     Threshold is 180 days, matching standard 6-month dental
--     recall intervals rather than a generic 12-month gap.
--     The reference date is derived from the data, not hardcoded,
--     so the query stays correct as the dataset grows.
--     HAVING, not WHERE: the filter applies to an aggregate.
-- ------------------------------------------------------------
WITH ref AS (
    SELECT MAX(scheduled_date) AS as_of FROM appointments
)
SELECT
    p.patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    p.insurance_type,
    MAX(a.scheduled_date) AS last_completed_visit,
    CAST(julianday((SELECT as_of FROM ref)) - julianday(MAX(a.scheduled_date)) AS INTEGER) AS days_since_visit
FROM patients p
JOIN appointments a ON p.patient_id = a.patient_id
WHERE a.status = 'Completed'
GROUP BY p.patient_id, patient_name, p.insurance_type
HAVING days_since_visit > 180
ORDER BY days_since_visit DESC;


-- ------------------------------------------------------------
-- Q8. Do no-show rates vary by insurance type?
--     Answer: not meaningfully. See README.
-- ------------------------------------------------------------
SELECT
    p.insurance_type,
    COUNT(*) AS total_booked,
    SUM(CASE WHEN a.status = 'No-show' THEN 1 ELSE 0 END) AS no_shows,
    ROUND(SUM(CASE WHEN a.status = 'No-show' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS no_show_rate
FROM appointments a
JOIN patients p ON a.patient_id = p.patient_id
GROUP BY p.insurance_type
ORDER BY no_show_rate DESC;
