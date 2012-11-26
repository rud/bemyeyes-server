"""
.. module:: bemyserver.model
	:synopsis: Provides general data structures used by the server
"""
__docformat__ = "restructuredtext en"

from datetime import datetime

class TwoMap(object):
	"""
	A reversible map for Python.  This makes it possible to look up results using either the key or the value.  The map direction is named explicitly when looking up values, to isolate namespace between keys and values.

	For example:

	>>> names = TwoMap()
	>>> names['Alice'] = 'Smith'
	>>> names['Joe'] = 'Bloggs'
	>>> names['Michael'] = 'Jackson'
	>>> names.first['Alice']
	'Smith'
	>>> names.second['Bloggs']
	'Joe'
	>>> names.first['Bloggs']
	Traceback (most recent call last):
	...
	KeyError: 'Bloggs'
	>>> len(names)
	3
	>>> values = TwoMap(first='number', second='letter', data=dict(a=1, b=2, c=3))
	>>> values.letter[3]
	'c'
	>>> values.number['a']
	1
	>>> values['d'] = 3
	>>> values.letter[3]
	'd'
	>>> values.number['d']
	3
	>>> values.number['c']
	Traceback (most recent call last):
	...
	KeyError: 'c'
	>>> values[3] = 'f'
	>>> values.letter['f']
	3
	>>> values.letter[3]
	'd'
	>>> values.number['f']
	Traceback (most recent call last):
	...
	KeyError: 'f'

	:param first: name of the mapping of key to value
	:param second: name of the mapping of value to key
	:param data: initial data to populate the map (should map first->second)
	:return: new TwoMap
	"""
	def __init__(self, first='first', second='second', data=None):
		if data is None:
			data = dict()
		self._first_name = first
		self._second_name = second
		self._first = dict(data)
		self._second = dict(reversed(item) for item in self._first.items())

	def __getattr__(self, key):
		if key == self._first_name:
			return self._first
		if key == self._second_name:
			return self._second
		raise AttributeError

	def __setitem__(self, first, second):
		old_second = None
		old_first = None
		if first in self._first:
			old_second = self._first[first]
		if second in self._second:
			old_first = self._second[second]

		if old_second is not None:
			del self._second[old_second]
		if old_first is not None:
			del self._first[old_first]

		self._first[first] = second
		self._second[second] = first

	def __len__(self):
		return len(self._first)

def enum(**enums):
	"""
	An enumeration type for Python, from http://stackoverflow.com/a/1695250/793212

	>>> Numbers = enum(ONE=1, TWO=2, THREE='three')
	>>> Numbers.ONE
	1
	>>> Numbers.TWO
	2
	>>> Numbers.THREE
	'three'

	:param enums: mappings of enumeration item to value
	:return: new enumeration
	"""
	return type('Enum', (), enums)

ClientLevel = enum(BANNED=0, USER=100, HELPER=1000, ADMIN=10000)
"""
A list of minimum values needed to enable certain features in the server
	BANNED
		The client is not allow to log in or use the server at all
	USER
		The client is able to request help from available helpers
	HELPER
		The client is able to answer help requests
	ADMIN
		The client is able to perform administrative functions, such as requesting server statistics.
"""

class Client(object):
	"""
	Represents any person who might be connected to this server and requesting its services.

	:param id: The database ID for the client
	:param email: The client's email address
	:param name: The client's full name
	:param apns_token: The APNS token used to send push messages to the client
	:param level: The numeric permission level of the client, used to control access to features.  Some predefined levels can be found in :py:data:`ClientLevel`
	:param available: Whether the client wishes to be available for chat sessions, or not
	"""

	def __init__(self, id, email, name, apns_token, level, available=False):
		""" Initializes a new :py:class:`Client` instance """
		self.id = id
		self.email = email
		self.name = name
		self.apns_token = apns_token
		self.level = level
		self.available = available

class ChatRequest(object):
	def __init__(self, request_id, from_client):
		self.request_id = request_id
		self.from_client = from_client
		self.active = True
		self.notified = set()

class ChatSession(object):
	"""
	Represents an established chat connection between two clients.

	:param session_id: Unique ID used to locate the chat
	:param remote_session: The session ID generated on the remote multimedia server
	:param request_id: The initial request that brought clients to this session, if any
	:param remote_tokens: A :py:class:`list` of authentication token allowing each client to connect to the chat
	:param start_date: A :py:class:`datetime.datetime` object containing the timestamp in UTC time for the start of the session.  If :py:const:`None` is supplied, the current time is used.
	"""
	def __init__(self, session_id, remote_session, request_id=None, start_date=None):
		""" Initializes a new :py:class:`ChatSession` instance """
		self.session_id = session_id
		self.start_date = start_date
		self.remote_session = remote_session
		self.request_id = request_id
		self.clients = list()
		self.remote_tokens = list()
		if start_date is None:
			start_date = datetime.utcnow()
		self.start_date = start_date
		self.end_date = None

	def add(self, client, remote_token):
		"""
		Adds a client to a chat session

		:param client: A client ID representing a chat participant
		:param remote_token: The token used to authorize the client to connect to the chat session
		"""
		self.clients.append(client)
		self.remote_tokens.append(remote_token)

	def remove(self, client):
		if not client in clients:
			return
		index = self.clients.index(client)
		clients.pop(index)
		remote_tokens.pop(index)
		if len(clients) == 0:
			self.end_date = datetime.utcnow()

	def clear(self):
		clients.clear()
		remote_tokens.clear()
		self.end_date = datetime.utcnow()
