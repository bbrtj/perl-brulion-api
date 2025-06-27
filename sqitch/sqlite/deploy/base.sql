-- Deploy brulion-api:base to sqlite

BEGIN;

CREATE TABLE brulion_boards(
	id CHAR(26) PRIMARY KEY NOT NULL,
	name VARCHAR(128) NOT NULL
);

CREATE UNIQUE INDEX ind_brulion_boards_name ON brulion_boards (name);

CREATE TABLE brulion_lanes(
	id CHAR(26) PRIMARY KEY NOT NULL,
	board_id CHAR(26) NOT NULL,
	sequence INTEGER NOT NULL DEFAULT 0,
	name VARCHAR(128) NOT NULL,
	FOREIGN KEY(board_id) REFERENCES brulion_boards(id) ON DELETE CASCADE
);

CREATE TABLE brulion_notes(
	id CHAR(26) PRIMARY KEY NOT NULL,
	lane_id CHAR(26) NOT NULL,
	sequence INTEGER NOT NULL DEFAULT 0,
	content TEXT NOT NULL,
	FOREIGN KEY(lane_id) REFERENCES brulion_lanes(id) ON DELETE CASCADE
);

COMMIT;

