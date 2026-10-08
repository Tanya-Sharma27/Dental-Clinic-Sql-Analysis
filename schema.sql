-- ============================================================
-- Dental Clinic Operations Database — Schema
-- Four tables modelling a small general dental practice.
-- Engine: SQLite
-- ============================================================

-- One row per patient.
CREATE TABLE patients (
    patient_id      INTEGER PRIMARY KEY,
    first_name      TEXT NOT NULL,
    last_name       TEXT NOT NULL,
    date_of_birth   DATE,
    sex             TEXT,
    insurance_type  TEXT,
    registered_on   DATE
);

-- Dentists and hygienists working in the practice.
CREATE TABLE providers (
    provider_id     INTEGER PRIMARY KEY,
    provider_name   TEXT NOT NULL,
    role            TEXT NOT NULL,
    joined_on       DATE
);

-- One row per scheduled visit. Links a patient to a provider.
-- status is the key operational field: Completed / No-show / Cancelled.
CREATE TABLE appointments (
    appointment_id   INTEGER PRIMARY KEY,
    patient_id       INTEGER NOT NULL,
    provider_id      INTEGER NOT NULL,
    scheduled_date   DATE NOT NULL,
    appointment_type TEXT,
    status           TEXT NOT NULL,
    FOREIGN KEY (patient_id)  REFERENCES patients(patient_id),
    FOREIGN KEY (provider_id) REFERENCES providers(provider_id)
);

-- Treatment actually delivered at a visit, with its fee.
-- Only completed appointments generate procedure rows.
CREATE TABLE procedures (
    procedure_id     INTEGER PRIMARY KEY,
    appointment_id   INTEGER NOT NULL,
    procedure_code   TEXT,
    procedure_name   TEXT,
    fee              REAL,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
);
