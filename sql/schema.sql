-- Database schema for By My Server

CREATE TABLE log_request_create(request_id text PRIMARY KEY, from_client text NOT NULL, stamp datetime NOT NULL DEFAULT current_timestamp);

CREATE TABLE log_request_notify(request_id text NOT NULL, to_client text NOT NULL, stamp datetime NOT NULL DEFAULT current_timestamp);

CREATE TABLE log_session(session_id text PRIMARY KEY, request_id text NOT NULL, remote_session_id text NOT NULL, from_client text NOT NULL, to_client text NOT NULL, start_date datetime NOT NULL DEFAULT current_timestamp, end_date datetime);
