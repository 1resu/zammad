class IndexRouter extends App.ControllerNavSidbar
  configKey: 'NavBarAdmin'

App.Config.set( 'manage', IndexRouter, 'Routes' )
App.Config.set( 'manage/:target', IndexRouter, 'Routes' )
App.Config.set( 'settings/:target', IndexRouter, 'Routes' )
App.Config.set( 'channels/:target', IndexRouter, 'Routes' )
App.Config.set( 'system/:target', IndexRouter, 'Routes' )


App.Config.set( 'Manage', { prio: 1000, name: 'Manage', target: '#manage', role: ['Admin'] }, 'NavBarAdmin' )
App.Config.set( 'Channels', { prio: 2500, name: 'Channels', target: '#channels', role: ['Admin'] }, 'NavBarAdmin' )
App.Config.set( 'Settings', { prio: 7000, name: 'Settings', target: '#settings', role: ['Admin'] }, 'NavBarAdmin' )
App.Config.set( 'System', { prio: 8000, name: 'System', target: '#system', role: ['Admin'] }, 'NavBarAdmin' )

App.Config.set( 'SystemObject', { prio: 1700, parent: '#system', name: 'Objects', target: '#system/objects', controller: true, role: ['Admin'] }, 'NavBarAdmin' )
