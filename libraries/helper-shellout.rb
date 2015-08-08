# Cookbook: selinux_policy
# Library: helper-disabled
# 2015, GPLv2, Nitzan Raz (http://backslasher.net)

require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

class Chef
  module SELinuxPolicy
    module Helpers
      # Checks if SELinux is disabled or otherwise unavailable and
      # whether we're allowed to run when disabled
      def use_selinux
        begin
          getenforce = shell_out!('getenforce')
        rescue
          selinux_disabled = true
        else
          selinux_disabled = getenforce.stdout =~ /disabled/i
        end
        allowed_disabled = node['selinux_policy']['allow_disabled']
        # return false only when SELinux is disabled and it's allowed
        return_val = !(selinux_disabled && allowed_disabled)
        Chef::Log.warn('SELinux is disabled / unreachable, skipping') if !return_val
        return return_val
      end

      def port_defined(port, protocol)
        cmd = <<-EOH.gsub(/^ {10}/, '')
          python << END
          import seobject, sys
          pr = seobject.portRecords().get_all()
          keys = filter(lambda x: x[0] <= #{port} <= x[1] and x[2] == '#{protocol}', pr.keys())
          if(keys):
            sys.stdout.write(pr[keys[0]][0])
            exit(0)
          else: exit(2)
          END
        EOH
        result = shell_out!(cmd, returns: [0, 2])
        defined = result.exitstatus == 0 ? true : false
        return defined, result.stdout
      end
    end
  end
end
