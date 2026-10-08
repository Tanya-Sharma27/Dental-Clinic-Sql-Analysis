-- ============================================================
-- Dental Clinic Operations Database — Data Load
-- Synthetic data: 6 providers, 60 patients, 300 appointments,
-- 482 procedure records.
-- Fees approximate US private-practice rates.
-- ============================================================

-- ---------- Providers ----------
INSERT INTO providers (provider_id, provider_name, role, joined_on) VALUES
(1, 'Dr. Anita Rao',      'Dentist',   '2019-03-01'),
(2, 'Dr. Peter Halloway', 'Dentist',   '2021-07-15'),
(3, 'Dr. Yusuf Karim',    'Dentist',   '2023-01-09'),
(4, 'Nina Petrov',        'Hygienist', '2020-05-04'),
(5, 'Chloe Bennett',      'Hygienist', '2022-02-14'),
(6, 'Derek Shaw',         'Hygienist', '2023-08-21');

-- ---------- Patients ----------
-- Generated with a recursive sequence rather than 60 typed rows.
INSERT INTO patients (patient_id, first_name, last_name, date_of_birth, sex, insurance_type, registered_on)
WITH RECURSIVE seq(n) AS (
    SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 60
)
SELECT
    n,
    CASE n % 12
        WHEN 0 THEN 'Victor' WHEN 1 THEN 'Aisha'  WHEN 2 THEN 'Marcus'
        WHEN 3 THEN 'Priya'  WHEN 4 THEN 'Daniel' WHEN 5 THEN 'Sofia'
        WHEN 6 THEN 'James'  WHEN 7 THEN 'Leila'  WHEN 8 THEN 'Omar'
        WHEN 9 THEN 'Grace'  WHEN 10 THEN 'Nathan' ELSE 'Ruby'
    END,
    CASE (n * 7) % 15
        WHEN 0 THEN 'Alvarez'  WHEN 1 THEN 'Brennan' WHEN 2 THEN 'Chen'
        WHEN 3 THEN 'Doyle'    WHEN 4 THEN 'Ellis'   WHEN 5 THEN 'Fontaine'
        WHEN 6 THEN 'Garza'    WHEN 7 THEN 'Hughes'  WHEN 8 THEN 'Iyer'
        WHEN 9 THEN 'Jensen'   WHEN 10 THEN 'Kowalski' WHEN 11 THEN 'Laurent'
        WHEN 12 THEN 'Mbeki'   WHEN 13 THEN 'Novak'  ELSE 'Okafor'
    END,
    date('1945-01-01', '+' || ((n * 7919) % 21900) || ' days'),
    CASE WHEN (n * 31) % 100 < 54 THEN 'F' ELSE 'M' END,
    CASE
        WHEN (n * 17) % 23 < 10 THEN 'PPO'
        WHEN (n * 17) % 23 < 16 THEN 'HMO'
        WHEN (n * 17) % 23 < 20 THEN 'Medicaid'
        ELSE 'Self-pay'
    END,
    date('2021-01-01', '+' || ((n * 7919) % 1400) || ' days')
FROM seq;

-- ---------- Appointments ----------
-- Hygiene-type visits are routed to hygienists, treatment to dentists.
INSERT INTO appointments (appointment_id, patient_id, provider_id, scheduled_date, appointment_type, status)
WITH RECURSIVE seq(n) AS (
    SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 300
),
base AS (
    SELECT n, (n * 3) % 10 AS t, (n * 7) % 11 AS s FROM seq
)
SELECT
    n,
    CASE WHEN n % 5 = 0 THEN ((n * 11) % 20) + 1 ELSE ((n * 37) % 60) + 1 END,
    CASE WHEN t IN (3, 4, 8, 9, 6) THEN 4 + (n % 3) ELSE 1 + (n % 3) END,
    date('2024-01-02', '+' || ((n * 29) % 640) || ' days'),
    CASE t
        WHEN 0 THEN 'Crown & Bridge'
        WHEN 1 THEN 'Emergency'
        WHEN 2 THEN 'Restorative'
        WHEN 5 THEN 'Restorative'
        WHEN 6 THEN 'Perio Maintenance'
        WHEN 7 THEN 'Extraction'
        ELSE 'Recall Exam & Cleaning'
    END,
    CASE
        WHEN s = 0 THEN 'No-show'
        WHEN s = 1 AND t IN (3, 4, 8, 9) THEN 'No-show'
        WHEN s = 2 THEN 'Cancelled'
        ELSE 'Completed'
    END
FROM base;

-- ---------- Data cleaning: remove weekend appointments ----------
-- Generated dates landed on Saturdays and Sundays, which the
-- practice does not schedule. Shift them into the following week.
UPDATE appointments SET scheduled_date = date(scheduled_date, '+2 days')
WHERE strftime('%w', scheduled_date) = '0';

UPDATE appointments SET scheduled_date = date(scheduled_date, '+2 days')
WHERE strftime('%w', scheduled_date) = '6';

-- ---------- Procedures ----------
-- Only completed appointments produce treatment and revenue.
-- A single visit can generate several procedure rows.

INSERT INTO procedures (appointment_id, procedure_code, procedure_name, fee)
SELECT appointment_id, 'D0120', 'Periodic oral evaluation', 65.00
FROM appointments WHERE status = 'Completed'
  AND appointment_type IN ('Recall Exam & Cleaning', 'Perio Maintenance');

INSERT INTO procedures (appointment_id, procedure_code, procedure_name, fee)
SELECT appointment_id, 'D1110', 'Prophylaxis - adult', 110.00
FROM appointments WHERE status = 'Completed'
  AND appointment_type = 'Recall Exam & Cleaning';

INSERT INTO procedures (appointment_id, procedure_code, procedure_name, fee)
SELECT appointment_id, 'D4910', 'Periodontal maintenance', 155.00
FROM appointments WHERE status = 'Completed'
  AND appointment_type = 'Perio Maintenance';

INSERT INTO procedures (appointment_id, procedure_code, procedure_name, fee)
SELECT appointment_id, 'D0274', 'Bitewings - four films', 85.00
FROM appointments WHERE status = 'Completed'
  AND appointment_type IN ('Recall Exam & Cleaning', 'Perio Maintenance')
  AND appointment_id % 2 = 0;

INSERT INTO procedures (appointment_id, procedure_code, procedure_name, fee)
SELECT appointment_id, 'D2391', 'Resin composite - one surface, posterior', 215.00
FROM appointments WHERE status = 'Completed' AND appointment_type = 'Restorative';

INSERT INTO procedures (appointment_id, procedure_code, procedure_name, fee)
SELECT appointment_id, 'D2392', 'Resin composite - two surfaces, posterior', 265.00
FROM appointments WHERE status = 'Completed' AND appointment_type = 'Restorative'
  AND appointment_id % 3 = 0;

INSERT INTO procedures (appointment_id, procedure_code, procedure_name, fee)
SELECT appointment_id, 'D7140', 'Extraction - erupted tooth', 230.00
FROM appointments WHERE status = 'Completed' AND appointment_type = 'Extraction';

INSERT INTO procedures (appointment_id, procedure_code, procedure_name, fee)
SELECT appointment_id, 'D0140', 'Limited oral evaluation - problem focused', 95.00
FROM appointments WHERE status = 'Completed' AND appointment_type = 'Emergency';

INSERT INTO procedures (appointment_id, procedure_code, procedure_name, fee)
SELECT appointment_id, 'D9110', 'Palliative treatment of dental pain', 140.00
FROM appointments WHERE status = 'Completed' AND appointment_type = 'Emergency'
  AND appointment_id % 2 = 1;

INSERT INTO procedures (appointment_id, procedure_code, procedure_name, fee)
SELECT appointment_id, 'D2740', 'Crown - porcelain/ceramic', 1450.00
FROM appointments WHERE status = 'Completed' AND appointment_type = 'Crown & Bridge';

INSERT INTO procedures (appointment_id, procedure_code, procedure_name, fee)
SELECT appointment_id, 'D2950', 'Core buildup, including any pins', 285.00
FROM appointments WHERE status = 'Completed' AND appointment_type = 'Crown & Bridge'
  AND appointment_id % 2 = 0;
