"""
.. module:: bemyserver.actions
	:synopsis: Actions that the server can perform
"""
__docformat__ = "restructuredtext en"

import uuid
import sqlite3
import OpenTokSDK as opentok
from bemyserver.model import ChatRequest, ChatSession
from bemyserver.log import Log

class Actions(object):
	def __init__(self, database, remote_api_key, remote_api_secret):
		db_connection = sqlite3.connect(database)
		self._log = Log(db_connection)
		self._available = set()
		self._chat_requests = dict()
		self._chat_sessions = dict()
		self._opentok = opentok.OpenTokSDK(remote_api_key, remote_api_secret)

	def disable_client(self, client_id):
		self._available.discard(client_id)
		print("Disabled " + client_id) #dbug

	def enable_client(self, client_id):
		self._available.add(client_id)
		print("Enabled " + client_id) #dbug

	def initiate_chat(self, client_id):
		self.disable_client(client_id)
		request_id = str(uuid.uuid4())
		request = ChatRequest(request_id, client_id)
		self._chat_requests[request_id] = request
		self._log.chat_request_create(request)
		return request

	def notify_all(self, request_id, handler):
		request = self._chat_requests[request_id]
		while request.active:
			available = self._available - request.notified
			if not available:
				break
			client_id = available.pop()
			handler.requestChat(client_id, request.request_id)
			request.notified.add(client_id)
			self._log.chat_request_notify(request_id, client_id)

	def accept_chat(self, request_id, client_id):
		request = self._chat_requests[request_id]
		if not request.active:
			return None
		request.active = False
		session = self._create_session(request_id, request.from_client, client_id)
		self.disable_client(client_id)
		del self._chat_requests[request_id]
		self._log.chat_session_create(session, request.from_client, client_id)
		return session

	def cancel_request(self, request_id, client_id):
		request = self._chat_requests[request_id]
		if not request.active:
			return
		if client_id != request.from_client:
			raise StandardError("Only the client that created the request may cancel it")
		request.active = False
		del self._chat_requests[request_id]
		return request

	def _create_session(request_id, from_id, to_id):
		remote_session = self._opentok.create_session()
		session_id = str(uuid.uuid4())
		session = ChatSession(session_id, remote_session, request_id)
		from_token = self._opentok.generate_token(remote_session.session_id, self._opentok.RoleConstants.PUBLISHER)
		to_token = self._opentok.generate_token(remote_session.session_id)
		session.add(from_id, from_token)
		session.add(to_id, to_token)
		self._chat_sessions[session_id] = session
		return session

	def leave_chat(self, session_id, client_id):
		session = self._chat_sessions[session_id]
		session.remove(client_id)
		if session.end_date:
			del self._chat_sessions[session_id]
			session.clear()
			self._log.chat_session_close(session)
		return session
