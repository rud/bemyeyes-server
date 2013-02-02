"""
.. module:: bemyserver.log
	:synopsis: Logging routines for server operations
"""
__docformat__ = "restructuredtext en"

class Log(object):
	"""
	Class containing methods that log events on the server.  A global instance of this class should be created, as it sets up a database connection for reading and writing log entries

	:param connection: An active database connection used for logging
	"""
	def __init__(self, connection):
		self._db = connection

	def chat_session_create(self, session):
		"""
		Logs the creation of a chat session

		:param session: The :py:class:`~bemyserver.model.ChatSession` instance
		"""
		with self._db as conn:
			conn.execute("""INSERT INTO log_session (session_id, remote_session_id) VALUES (?, ?)""", (session.session_id, session.remote_session))
			conn.executemany("""INSERT INTO log_session_participant (session_id, client_id) VALUES (?, ?)""", ((session.session_id, client) for client in session.clients))

	def chat_session_close(self, session):
		"""
		Logs the closing of a chat session

		:param session: The :py:class:`~bemyserver.model.ChatSession` instance
		"""
		with self._db as conn:
			conn.execute("""UPDATE log_session SET end_date = current_timestamp WHERE session_id = ?""", (session.session_id, ))
