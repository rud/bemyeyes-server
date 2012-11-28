"""
.. module:: bemyserver.actions
	:synopsis: Actions that the server can perform
"""
__docformat__ = "restructuredtext en"

import uuid
import sqlite3
import OpenTokSDK as opentok
from bemyserver.model import ChatSession
from bemyserver.log import Log

class Actions(object):
	def __init__(self, database, remote_api_key, remote_api_secret):
		db_connection = sqlite3.connect(database)
		self._log = Log(db_connection)
		self._available = set()
		self._engaged = set()
		self._chat_sessions = dict()
		self._opentok = opentok.OpenTokSDK(remote_api_key, remote_api_secret)

	def disable_client(self, client_id):
		self._available.discard(client_id)

	def enable_client(self, client_id):
		self._available.add(client_id)

	def engage_client(self, client_id=None):
		if client_id is None:
			client_id = self._available.pop()
		else:
			self._available.discard(client_id)
		self._engaged.add(client_id)
		return client_id

	def initiate_chat(self, client_id):
		self.disable_client(client_id)
		session_id = str(uuid.uuid4())
		remote_session = self._opentok.create_session()
		session = ChatSession(session_id, remote_session)
		for token in range(2):
			session.remote_tokens.append(self._opentok.generate_token(remote_session.session_id, self._opentok.RoleConstants.PUBLISHER))
		to_id = self.engage_client()
		session.add(from_id)
		session.add(to_id)
		self._chat_sessions[session_id] = session
		self._log.chat_session_create(session)
		return session

	def leave_chat(self, session_id, client_id):
		session = self._chat_sessions[session_id]
		session.remove(client_id)
		if session.end_date:
			del self._chat_sessions[session_id]
			self._log.chat_session_close(session)
		return session
