-- Revert brulion-api:base from sqlite

BEGIN;

DROP TABLE brulion_notes;
DROP TABLE brulion_lanes;
DROP TABLE brulion_boards;

COMMIT;

