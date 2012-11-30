"""
.. module:: bemyserver.application
	:synopsis: Application runnable under Twisted
"""
__docformat__ = "restructuredtext en"

import sqlite3
from ConfigParser import RawConfigParser

import OpenTokSDK as opentok
from twisted.application.service import Application
from wokkel.component import Component
from bemyserver.component import MasterHandler
from bemyserver.actions import Actions

config = RawConfigParser()
config.read(('config.ini', '../config.ini'))

application = Application(config.get('component', 'jid'))

xmpp_component = Component(config.get('server', 'host'), config.getint('server', 'port'), config.get('component', 'jid'), config.get('server', 'secret'))
xmpp_component.logTraffic = config.getboolean('component', 'log_traffic')
database_connection = sqlite3.connect(config.get('database', 'path'))
opentok_api = opentok.OpenTokSDK(config.get('opentok', 'api_key'), config.get('opentok', 'api_secret'))
actions = Actions(database_connection, opentok_api)
handler = MasterHandler(actions, config, xmpp_component)
xmpp_component.setServiceParent(application)
