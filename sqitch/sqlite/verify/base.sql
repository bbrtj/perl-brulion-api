-- Verify brulion-api:base on sqlite

BEGIN;

SELECT * FROM brulion_boards;
SELECT * FROM brulion_lanes;
SELECT * FROM brulion_notes;

ROLLBACK;

