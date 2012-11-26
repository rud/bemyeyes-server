"""
.. module:: bemyserver.component
	:synopsis: XEP-0114 component that makes it all happen
"""
__docformat__ = "restructuredtext en"

from twisted.words.xish import domish
from twisted.words.protocols.jabber.jid import JID
from twisted.words.protocols.jabber.error import StanzaError
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
		self.unsubscribed(presence.sender) # users can't subscribe to the service
		self.subscribe(presence.sender) # request a subscription

	def probeReceived(self, probe):
		self.available(probe.sender) # we are always available

class MessageHandler(MessageProtocol):
	def __init__(self, master):
		MessageProtocol.__init__(self)
		self._master = master

	def onMessage(self, message):
		if message['type'] == 'chat' and message.body:
			error = StanzaError('service-unavailable')
			self.send(error.toResponse(message))

class DiscoHandler(DiscoClientProtocol):
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

	def onChatCancel(self, iq):
		client_id = iq['from']
		request_id = iq.command.request_id
		request = self._master.actions.cancel_request(request_id, client_id)
		result = command_iq_to_element(iq, 'canceled')
		result.addElement('request_id', kChatXMLNS, request_id)
		if request:
			# TODO: send cancellations
			pass
		else:
			result.addElement('note', None, 'The requested chat is not available')
			result.note['type'] = 'error'
		return result

	def onChatRequest(self, iq):
		if iq.command['action'] == 'cancel':
			return onChatCancel(self, iq)
		client_id = iq['from']
		request = self._master.actions.initiate_chat(client_id)
		result = command_iq_to_element(iq)
		self._master.actions.notify_all(request.request_id, self) # TODO: async
		result.addElement('request_id', kChatXMLNS, request.request_id)
		return result

	def onChatAccept(self, iq):
		client_id = iq['from']
		request_id = iq.command.request_id
		session = self._master.actions.accept_chat(request_id, client_id)
		result = command_iq_to_element(iq)
		result.addElement('request_id', kChatXMLNS, request_id)
		if session:
			# TODO: send session notification
			pass
		else:
			result.addElement('note', None, 'The requested chat is not available')
			result.note['type'] = 'error'
		# TODO: send cancellations
		return result

	def onChatLeave(self, iq):
		client_id = iq['from']
		session_id = iq.command.session_id
		session = self._master.actions.leave_chat(session_id, client_id)
		result = command_iq_to_element(iq)
		result.addElement('session_id', kChatXMLNS, session_id)
		return result

	def requestChat(self, client_id, request_id):
		iq = Request(recipient=JID(client_id), stanzaType='set')
		iq = iq.toElement()
		command = domish.Element((kCommandXMLNS, 'command'))
		command['node'] = kCommandNodePrefix + 'chat#request'
		command['action'] = 'execute'
		command.addElement('request_id', kChatXMLNS, request_id)
		iq.addChild(command)
		#iq = Request.fromElement(iq)
		result = self.send(iq)
		return result
