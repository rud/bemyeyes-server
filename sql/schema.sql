-- Database schema for By My Server

CREATE TABLE log_session(session_id text PRIMARY KEY, remote_session_id text NOT NULL, start_date datetime NOT NULL DEFAULT current_timestamp, end_date datetime);

CREATE TABLE log_session_participant(session_id text NOT NULL, client_id text NOT NULL);
