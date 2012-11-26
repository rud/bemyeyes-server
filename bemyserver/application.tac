"""
.. module:: bemyserver.application
	:synopsis: Application runnable under Twisted
"""
__docformat__ = "restructuredtext en"

from ConfigParser import RawConfigParser
from twisted.application.service import Application
from wokkel.component import Component
from bemyserver.component import MasterHandler
from bemyserver.actions import Actions

config = RawConfigParser()
config.read(('config.ini', '../config.ini'))

application = Application(config.get('server', 'component_jid'))

xmpp_component = Component(config.get('server', 'host'), config.getint('server', 'port'), config.get('server', 'component_jid'), config.get('server', 'secret'))
xmpp_component.logTraffic = config.getboolean('component', 'log_traffic')
actions = Actions(config.get('database', 'path'), config.get('opentok', 'api_key'), config.get('opentok', 'api_secret'))
handler = MasterHandler(actions, xmpp_component)
xmpp_component.setServiceParent(application)
