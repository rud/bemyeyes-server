"""
.. module:: bemyserver.component
	:synopsis: XEP-0114 component that makes it all happen
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

kCommandNodePrefix = 'bemyserver:'
kCommandXMLNS = "http://jabber.org/protocol/commands"
kChatXMLNS = 'bemyserver:chat'

class MasterHandler(object):
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
		for item in items:
			jid = item.entity
			self._presence.probe(jid)

	def confirmChatRequest(self, iq):
		log.msg("Chat request confirmation from {}".format(iq['from']))

class PresenceHandler(PresenceProtocol):
	def __init__(self, master):
		PresenceProtocol.__init__(self)
		self._master = master

	def availableReceived(self, presence):
		if presence.show in ('dnd', 'away', 'xa'):
			self._master.actions.disable_client(presence.sender.full())
		else:
			self._master.actions.enable_client(presence.sender.full())

	def unavailableReceived(self, presence):
		self._master.actions.disable_client(presence.sender.full())

	def subscribeReceived(self, presence):
		self.subscribed(presence.sender) # sure, why not?
		self.subscribe(presence.sender)

	def probeReceived(self, probe):
		self.available(probe.sender)

class MessageHandler(MessageProtocol):
	def __init__(self, master):
		MessageProtocol.__init__(self)
		self._master = master

	def onMessage(self, message):
		if message['type'] == 'chat' and message.body:
			error = StanzaError('service-unavailable')
			self.send(error.toResponse(message))

class DiscoHandler(DiscoClientProtocol):
	"""
	Service discovery handler

	TODO: handle discovery requests from clients
	"""
	def __init__(self, master):
		DiscoClientProtocol.__init__(self)
		self._master = master

	def connectionMade(self):
		response = self.requestItems(JID(self._master.config.get('server', 'jid')), nodeIdentifier='online users', sender=JID(u'{}@{}'.format(self._master.config.get('component', 'admin_user'), self._master.config.get('component', 'jid'))))
		response.addCallback(self._master.onlineUsers)

def command_iq_to_element(iq, status='completed'):
	element = domish.Element((kCommandXMLNS, 'command'))
	element['node'] = iq.command['node']
	element['status'] = status
	return element

class CommandHandler(XMPPHandler, IQHandlerMixin):
	kCommand = "/iq[@type='set']/command[@xmlns='" + kCommandXMLNS + "']"

	iqHandlers = { kCommand : 'onCommand', }

	subHandlers = {
		'chat#request': 'onChatRequest',
		'chat#accept': 'onChatAccept',
		'chat#leave': 'onChatLeave',
	}

	def __init__(self, master):
		XMPPHandler.__init__(self)
		IQHandlerMixin.__init__(self)
		self._master = master

	def connectionInitialized(self):
		self.xmlstream.addObserver(CommandHandler.kCommand, self.handleRequest)

	def onCommand(self, iq):
		node = iq.command['node']
		command = node.replace(kCommandNodePrefix, '')
		return getattr(self, CommandHandler.subHandlers[command])(iq)

	def onChatRequest(self, iq):
		client_id = iq['from']
		session = self._master.actions.initiate_chat(client_id)
		for invitee in session.clients[1:]:
			response = self.requestChat(JID(invitee), session.session_id, session.remote_session_id, session.remote_tokens.pop())
			response.addCallback(self._master.confirmChatRequest)
		result = command_iq_to_element(iq)
		result.addElement('session_id', kChatXMLNS, session.session_id)
		result.addElement('remote_session_id', kChatXMLNS, session.remote_session_id)
		result.addElement('remote_token', kChatXMLNS, session.remote_tokens.pop())
		return result

	def onChatLeave(self, iq):
		client_id = iq['from']
		session_id = iq.command.session_id
		session = self._master.actions.leave_chat(session_id, client_id)
		result = command_iq_to_element(iq)
		result.addElement('session_id', kChatXMLNS, session_id)
		return result

	def requestChat(self, client_id, session_id, remote_session_id, remote_token):
		iq = Request(recipient=JID(client_id), stanzaType='set')
		iq = iq.toElement()
		command = domish.Element((kCommandXMLNS, 'command'))
		command['node'] = kCommandNodePrefix + 'chat#request'
		command['action'] = 'execute'
		command.addElement('session_id', kChatXMLNS, session_id)
		command.addElement('remote_session_id', kChatXMLNS, remote_session_id)
		command.addElement('remote_token', kChatXMLNS, remote_token)
		iq.addChild(command)
		result = self.send(iq)
		return result
