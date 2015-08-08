include Chef::SELinuxPolicy::Helpers

# Support whyrun
def whyrun_supported?
  true
end

use_inline_resources

def load_current_resource
  @use_selinux = use_selinux
  if @use_selinux
    @defined, @context = port_defined(new_resource.port, new_resource.protocol)
  end
end

# Create if doesn't exist, do not touch if port is already registered (even under different type)
action :add do
  execute "selinux-port-#{new_resource.port}-add" do
    command "/usr/sbin/semanage port -a -t #{new_resource.secontext} -p #{new_resource.protocol} #{new_resource.port}"
    only_if { @use_selinux }
    not_if { @defined }
  end
end

# Delete if exists
action :delete do
  execute "selinux-port-#{new_resource.port}-delete" do
    command "/usr/sbin/semanage port -d -p #{new_resource.protocol} #{new_resource.port}"
    only_if { @use_selinux && @defined }
  end
end

action :modify do
  execute "selinux-port-#{new_resource.port}-modify" do
    command "/usr/sbin/semanage port -m -t #{new_resource.secontext} -p #{new_resource.protocol} #{new_resource.port}"
    only_if { @use_selinux && @defined && @context != new_resource.secontext }
  end
end

action :addormodify do
  option = @defined ? '-m' : '-a'
  execute "selinux-port-#{new_resource.port}-addormodify" do
    command "/usr/sbin/semanage port #{option} -t #{new_resource.secontext} -p #{new_resource.protocol} #{new_resource.port}"
    only_if { @use_selinux }
    not_if { @defined && @context == new_resource.secontext }
  end
end
