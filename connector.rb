require 'msfrpc-client'

user = 'msf'
pass = 'msf'

opts = {
  host: '172.17.0.2',
  port: 55553,
  uri:  '/api/',
  ssl:  false
}
rpc = Msf::RPC::Client.new(opts)
rpc.login(user, pass)
print rpc.call('core.version')
