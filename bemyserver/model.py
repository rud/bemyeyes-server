"""
.. module:: bemyserver.model
	:synopsis: Provides general data structures used by the server
"""
__docformat__ = "restructuredtext en"

from datetime import datetime

class ChatSession(object):
	"""
	Represents an established chat connection between two clients.

	:param session_id: Unique ID used to locate the chat
	:param remote_session: The session ID generated on the remote chat server
	:param request_id: The initial request that brought clients to this session, if any
	:param remote_tokens: A :py:class:`list` of authentication token allowing each client to connect to the chat
	:param start_date: A :py:class:`datetime.datetime` object containing the timestamp in UTC time for the start of the session.  If :py:const:`None` is supplied, the current time is used.

	:ivar session_id: Unique ID used to locate the chat
	:ivar start_date: The date the chat began, in UTC time
	:ivar remote_session: The session ID generated on the remote chat server
	:ivar clients: A list of participants in the chat session
	:ivar remote_tokens: A list of generated, but unused, authentication tokens for the remote chat server session.  These should be removed from the list as they are handed out to clients.
	:ivar end_date: The date the chat ended, in UTC time.  This will be :py:const:`None` if the session is still active.
	"""
	def __init__(self, session_id, remote_session, start_date=None):
		""" Initializes a new :py:class:`ChatSession` instance """
		self.session_id = session_id
		self.start_date = start_date
		self.remote_session = remote_session
		self.clients = list()
		self.remote_tokens = list()
		if start_date is None:
			start_date = datetime.utcnow()
		self.start_date = start_date
		self.end_date = None

	def add(self, client):
		"""
		Adds a client to the chat session

		:param client: The client ID to add to the chat
		"""
		self.clients.append(client)

	def remove(self, client):
		"""
		Removes a client from the chat session.  If there are no more clients left, the :py:data:`end_date` is set to the current time, and the session is considered closed.

		:param client: The client ID to remove from the chat
		"""
		try:
			self.clients.remove(client)
		except ValueError:
			pass
		if len(clients) == 0:
			self.end_date = datetime.utcnow()

	def clear(self):
		"""
		Removes all clients from the chat session, also clearing any generated authentication tokens.  The :py:data:`end_date` is set to the current time, and the session is considered closed.
		"""
		clients.clear()
		remote_tokens.clear()
		if not self.end_date:
			self.end_date = datetime.utcnow()
