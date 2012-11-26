"""
.. module:: bemyserver.log
	:synopsis: Logging routines for server operations
"""
__docformat__ = "restructuredtext en"

class Log(object):
	"""
	Class containing methods that log events on the server.  A global instance of this class should be created, as it sets up a database connection for reading and writing log entries
	"""
	def __init__(self, connection):
		self._db = connection

	def chat_request_create(self, request):
		with self._db as conn:
			conn.execute("""INSERT INTO log_request_create (request_id, from_client) VALUES (?, ?)""", (request.request_id, request.from_client))

	def chat_request_notify(self, request_id, to_id):
		with self._db as conn:
			conn.execute("""INSERT INTO log_request_notify (request_id, to_client) VALUES (?, ?)""", (request_id, to_id))

	def chat_session_create(self, session, from_id, to_id):
		with self._db as conn:
			conn.execute("""INSERT INTO log_session (session_id, request_id, remote_session_id, from_client, to_client) VALUES (?, ?, ?, ?, ?)""", (session.session_id, session.request_id, session.remote_session_id, from_id, to_id))

	def chat_session_close(self, session):
		with self._db as conn:
			conn.execute("""UPDATE log_session SET end_date = current_timestamp WHERE session_id = ?""", (session.session_id, ))
