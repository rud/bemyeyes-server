"""
.. module:: bemyserver.component
	:synopsis: XEP-0114 server component that sends and receives network requests
"""
__docformat__ = "restructuredtext en"

from twisted.words.xish import domish
from twisted.words.protocols.jabber.jid import JID
from twisted.words.protocols.jabber.error import StanzaError
from twisted.python import log
from wokkel.xmppim import MessageProtocol, PresenceProtocol
from wokkel.disco import DiscoClientProtocol
from wokkel.generic import FallbackHandler, Request
from wokkel.ping import PingHandler
from wokkel.subprotocols import XMPPHandler, IQHandlerMixin

kCommandNodePrefix = 'bemyserver:' #: The namespace prefix used for command nodes in this component

kCommandXMLNS = "http://jabber.org/protocol/commands" #: The XML namespace for XEP-0050 commands

kChatXMLNS = 'bemyserver:chat' #: The namespace prefix used for chat command nodes

class MasterHandler(object):
	"""
	Collects all of the subprotocol handlers into one place, giving them all access to each other, and to the :py:class:`~bemyserver.actions.Actions` instance.

	:param actions: the :py:class:`~bemyserver.actions.Actions` instance that should handle all business logic
	:param config: A :py:class:`~ConfigParser.ConfigParser` instance containing configuration values
	:param parent: The parent handler for each of the subprotocol handlers
	"""
	def __init__(self, actions, config, parent):
		self.actions = actions
		self.config = config
		self._command = CommandHandler(self)
		self._command.setHandlerParent(parent)
		self._message = MessageHandler(self)
		self._message.setHandlerParent(parent)
		self._presence = PresenceHandler(self)
		self._presence.setHandlerParent(parent)
		self._disco = DiscoHandler(self)
		self._disco.setHandlerParent(parent)
		self._fallback = FallbackHandler()
		self._fallback.setHandlerParent(parent)
		self._ping = PingHandler()
		self._ping.setHandlerParent(parent)

	def onlineUsers(self, items):
		"""
		Sends a presence probe to each client in the list of clients.  This is meant to be executed as a callback when results come in from a service discovery request to the XMPP server for all online users.

		:param items: A :py:class:`wokkel.disco.DiscoItems` instance containing a list of service discovery items
		"""
		for item in items:
			jid = item.entity
			self._presence.probe(jid)

	def confirmChatRequest(self, iq):
		"""
		Called when a client confirms acceptance of a chat request.  At the moment, this just logs a message.

		:param iq: The IQ stanza containing the confirmation message
		"""
		log.msg("Chat request confirmation from {}".format(iq['from']))

class PresenceHandler(PresenceProtocol):
	"""
	Subprotocol handler for client presence messages.  This is the place where availability of clients is tracked.

	:param master: The :py:class:`MasterHandler` instance
	"""
	def __init__(self, master):
		PresenceProtocol.__init__(self)
		self._master = master

	def availableReceived(self, presence):
		"""
		Called when a presence stanza with an `available` status arrives.  This updates the pool of available clients based on the `show` element.

		:param presence: A :py:class:`wokkel.xmppim.AvailabilityPresence` instance
		"""
		if presence.show in ('dnd', 'away', 'xa'):
			self._master.actions.disable_client(presence.sender.full())
		else:
			self._master.actions.enable_client(presence.sender.full())

	def unavailableReceived(self, presence):
		"""
		Called when a presence stanza with an `unavailable` status arrives.  This removes the sending client from the pool of available clients.

		:param presence: A :py:class:`wokkel.xmppim.AvailabilityPresence` instance
		"""
		self._master.actions.disable_client(presence.sender.full())

	def subscribeReceived(self, presence):
		"""
		Called when a client subscribes to presence notifications from this component.  The subscription request is always approved, and in response, a subscription request is sent to the client as well.

		:param presence: A :py:class:`wokkel.xmppim.SubscriptionPresence` instance
		"""
		self.subscribed(presence.sender) # sure, why not?
		self.subscribe(presence.sender)

	def probeReceived(self, probe):
		"""
		Called when a client sends a presence probe.  The response is always set to "available".

		:param probe: A :py:class:`wokkel.xmppim.ProbePresence` instance
		"""
		self.available(probe.sender)

class MessageHandler(MessageProtocol):
	"""
	Handler for XMPP messages

	:param master: The :py:class:`MasterHandler` instance
	"""
	def __init__(self, master):
		MessageProtocol.__init__(self)
		self._master = master

	def onMessage(self, message):
		"""
		Called when an XMPP message arrives.  All chat messages are answered with a `service-unavailable <http://tools.ietf.org/html/rfc6120#section-8.3.3.19>`_ error; other messages are ignored.

		:param message: A :py:class:`wokkel.xmppim.Message` instance
		"""
		if message['type'] == 'chat' and message.body:
			error = StanzaError('service-unavailable')
			self.send(error.toResponse(message))

class DiscoHandler(DiscoClientProtocol):
	"""
	Handler for XMPP service discovery messages

	:param master: The :py:class:`MasterHandler` instance

	:todo: handle discovery requests from clients
	"""
	def __init__(self, master):
		DiscoClientProtocol.__init__(self)
		self._master = master

	def connectionMade(self):
		"""
		Called on connection to the XMPP server.  This sends a service discovery request for all online users.  The results go to :py:meth:`MasterHandler.onlineUsers` for processing
		"""
		response = self.requestItems(JID(self._master.config.get('server', 'jid')), nodeIdentifier='online users', sender=JID(u'{}@{}'.format(self._master.config.get('component', 'admin_user'), self._master.config.get('component', 'jid'))))
		response.addCallback(self._master.onlineUsers)

def command_iq_to_element(iq, status='completed'):
	"""
	Builds an ad-hoc command (`XEP-0050 <http://xmpp.org/extensions/xep-0050.html>`_) stanza to insert into an outgoing IQ response
	
	:param iq: The original IQ message corresponding to the request
	:param status: The command status
	
	:return: A :py:class:`twisted.words.xish.domish.Element` instance containing the response
	"""
	element = domish.Element((kCommandXMLNS, 'command'))
	element['node'] = iq.command['node']
	element['status'] = status
	return element

class CommandHandler(XMPPHandler, IQHandlerMixin):
	"""
	Subprotocol handler for ad-hoc commands (`XEP-0050 <http://xmpp.org/extensions/xep-0050.html>`_)
	
	:param iq: The original IQ message corresponding to the request
	:param status: The command status
	
	:return: A :py:class:`twisted.words.xish.domish.Element` instance containing the response
	"""
	def __init__(self, master):
		XMPPHandler.__init__(self)
		IQHandlerMixin.__init__(self)
		self._master = master

	kCommand = "/iq[@type='set']/command[@xmlns='" + kCommandXMLNS + "']" #: An XPATH query that matches incoming command requests

	iqHandlers = { kCommand : 'onCommand', } #: Mapping of XPATH query to handler.  In this case, the only mapping is from :py:data:`kCommand` to :py:meth:`onCommand`.

	subHandlers = {
		'chat#request': 'onChatRequest',
		'chat#leave': 'onChatLeave',
	} #: This is a mapping of command node to a local handler

	def connectionInitialized(self):
		"""
		Adds the command mapping on startup
		"""
		self.xmlstream.addObserver(CommandHandler.kCommand, self.handleRequest)

	def onCommand(self, iq):
		"""
		Reads the command node and calls a subhandler based on the :py:data:`subHandlers` mapping

		:param iq: The incoming IQ message containing a command
		:return: The results of the subhandler
		"""
		node = iq.command['node']
		command = node.replace(kCommandNodePrefix, '')
		return getattr(self, CommandHandler.subHandlers[command])(iq)

	def onChatRequest(self, iq):
		"""
		Called when a chat request comes in.  This sets up a session by calling :py:meth:`~bemyserver.actions.Actions.initiate_chat`, then sends a chat request via :py:meth:`requestChat`, then sends a success response back to the requesting client.

		:param iq: The incoming IQ message containing the chat request command
		:return: The response stanza
		"""
		client_id = iq['from']
		session = self._master.actions.initiate_chat(client_id)
		for invitee in session.clients[1:]:
			response = self.requestChat(invitee, session.session_id, session.remote_session, session.remote_tokens.pop())
			response.addCallback(self._master.confirmChatRequest)
		result = command_iq_to_element(iq)
		result.addElement('session_id', kChatXMLNS, session.session_id)
		result.addElement('remote_session_id', kChatXMLNS, session.remote_session)
		result.addElement('remote_token', kChatXMLNS, session.remote_tokens.pop())
		return result

	def onChatLeave(self, iq):
		"""
		Called when a client notifies the server that it has left the chat.  This calls :py:meth:`~bemyserver.actions.Actions.leave_chat`, then sends a success response back to the requesting client.

		:param iq: The incoming IQ message containing the chat leave command
		:return: The response stanza
		"""
		client_id = iq['from']
		session_id = iq.command.session_id
		session = self._master.actions.leave_chat(session_id, client_id)
		result = command_iq_to_element(iq)
		result.addElement('session_id', kChatXMLNS, session_id)
		return result

	def requestChat(self, client_id, session_id, remote_session_id, remote_token):
		"""
		Sends a chat request to a client, with all necessary information for that client to join an existing chat session

		:param client_id: The JID of the client to contact
		:param session_id: The local session ID
		:param remote_session_id: The session ID on the remote chat server
		:param remote_token: The authentication token for the remote chat session

		:return: The client's response to the request (deferred)
		"""
		iq = Request(recipient=JID(client_id), stanzaType='set')
		iq = iq.toElement()
		command = domish.Element((kCommandXMLNS, 'command'))
		command['node'] = kCommandNodePrefix + 'chat#request'
		command['action'] = 'execute'
		command.addElement('session_id', kChatXMLNS, session_id)
		command.addElement('remote_session_id', kChatXMLNS, remote_session_id)
		command.addElement('remote_token', kChatXMLNS, remote_token)
		iq.addChild(command)
		result = self.request(iq)
		return result
