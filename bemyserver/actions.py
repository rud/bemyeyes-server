"""
.. module:: bemyserver.actions
	:synopsis: Actions that the server can perform
"""
__docformat__ = "restructuredtext en"

import uuid
from bemyserver.model import ChatSession
from bemyserver.log import Log

class Actions(object):
	"""
	Logic for actions that can be performed in the server lives in this class

	:param database: An active database connection, used for logging
	:param opentok: An initialized instance of the OpenTok API, for communicating with remote servers
	"""
	def __init__(self, database, opentok):
		self._log = Log(database)
		self._available = set()
		self._chat_sessions = dict()
		self._opentok = opentok

	def disable_client(self, client_id):
		"""
		Removes a client from the pool of available (contactable) clients

		:param client_id: The JID of the client to remove
		"""
		self._available.discard(client_id)

	def enable_client(self, client_id):
		"""
		Adds a client to the pool of available (contactable) clients

		:param client_id: The JID of the client to add
		"""
		self._available.add(client_id)

	def engage_client(self, client_id=None):
		"""
		Retrieves a client from the pool of available clients, marking it unavailable in the process.

		Example:
			>>> actions = Actions(None, None)
			>>> actions.enable_client('test@example.org/mobile')
			>>> actions.enable_client('admin@example.org/home')
			>>> actions.enable_client('client@example.org/mobile')
			>>> actions.engage_client('admin@example.org/home')
			'admin@example.org/home'
			>>> actions.engage_client('client@example.org/mobile')
			'client@example.org/mobile'
			>>> actions.engage_client()
			'test@example.org/mobile'
			>>> actions.engage_client('someone_else@example.org/none')
			'someone_else@example.org/none'
			>>> actions.engage_client()
			Traceback (most recent call last):
			...
			KeyError: 'No clients available'

		:param client_id: The JID of the client to retrieve.  If :py:const:`None`, a random client will be chosen from the pool.
		:return: The client_id, which was either supplied or chosen randomly.
		"""
		if client_id is None:
			try:
				client_id = self._available.pop()
			except KeyError:
				raise KeyError('No clients available') # slightly prettier message
		else:
			self._available.discard(client_id)
		return client_id

	def initiate_chat(self, client_id):
		"""
		Sets up a new chat session, requested by the supplied client.  This method creates a remote session on the chat server, generates a pair of authentication tokens for that chat, and chooses a random client from the available pool.

		:param client_id: The client requesting the chat
		:return: A :py:class:`bemyserver.model.ChatSession` object containing the requesting client and a randomly chosen answering client
		"""
		self.disable_client(client_id)
		session_id = str(uuid.uuid4())
		remote_session = self._opentok.create_session()
		session = ChatSession(session_id, remote_session.session_id)
		for token in range(2):
			session.remote_tokens.append(self._opentok.generate_token(remote_session.session_id))
		to_id = self.engage_client()
		session.add(client_id)
		session.add(to_id)
		self._chat_sessions[session_id] = session
		self._log.chat_session_create(session)
		return session

	def leave_chat(self, session_id, client_id):
		"""
		Records a client as having left a chat session.  Once all clients have left the chat session, the session will be marked as ended, and logged in the database.

		:param session_id: The local session ID of the chat
		:param client_id: The client leaving the chat session
		:return: The :py:class:`bemyserver.model.ChatSession` object containing the updated local session information
		"""
		session = self._chat_sessions[session_id]
		session.remove(client_id)
		if session.end_date:
			del self._chat_sessions[session_id]
			self._log.chat_session_close(session)
		return session
