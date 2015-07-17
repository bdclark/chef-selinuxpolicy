include Chef::SELinuxPolicy::Helpers

# Support whyrun
def whyrun_supported?
  true
end

use_inline_resources

def port_defined(port_b,port_t,proto)
  "port_b=#{port_b};port_t=#{port_t};proto='#{proto}';context='#{context}'"+
'import seobject
pr=seobject.portRecords().get_all()
keys=filter(lambda x: pr.keys());
if(keys): exit(0)
else: exit(2)'
end

def port_match_context(port_b,port_t,proto,context)
  "port_b=#{port_b};port_t=#{port_t};proto='#{proto}';context='#{context}'"+
'import seobject
pr=seobject.portRecords().get_all()
keys=filter(lambda x: pr.keys());
if(keys):
  val=pr[keys[0]][0]
  if val==context: exit(0)
  else: exit(1)
else: exit(2)'
end

# Create if doesn't exist, do not touch if port is already registered (even under different type)
action :add do
  execute "selinux-port-#{new_resource.port}-add" do
    command "/usr/sbin/semanage port -a -t #{new_resource.secontext} -p #{new_resource.protocol} #{new_resource.port}"
    guard_interpreter :python
    not_if port_defined(new_resource.port,new_resource.port,new_resource.protocol)
    only_if {use_selinux}
  end
end

# Delete if exists
action :delete do
  execute "selinux-port-#{new_resource.port}-delete" do
    command "/usr/sbin/semanage port -d -p #{new_resource.protocol} #{new_resource.port}"
    guard_interpreter :python
    only_if port_defined(new_resource.port,new_resource.port,new_resource.protocol)
    only_if {use_selinux}
  end
end

action :modify do
  execute "selinux-port-#{new_resource.port}-modify" do
    command "/usr/sbin/semanage port -m -t #{new_resource.secontext} -p #{new_resource.protocol} #{new_resource.port}"
    only_if {use_selinux}
  end
end

action :addormodify do
  execute "selinux-port-#{new_resource.port}-addormodify" do
    command <<-EOT
    if /usr/sbin/semanage port -l | grep -P '#{new_resource.protocol}\\s+#{new_resource.port}'>/dev/null; then
      /usr/sbin/semanage port -m -t #{new_resource.secontext} -p #{new_resource.protocol} #{new_resource.port}
    else
      /usr/sbin/semanage port -a -t #{new_resource.secontext} -p #{new_resource.protocol} #{new_resource.port}
    fi
    EOT
    guard_interpreter :python
    not_if port_defined(new_resource.port,new_resource.port,new_resource.protocol,new_resource.secontext)
    only_if {use_selinux}
  end
end
