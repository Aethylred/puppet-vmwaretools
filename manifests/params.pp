# == Class: vmwaretools::params
#
# This class handles parameters for the vmwaretools module, including the logic
# that decided if we should install a new version of VMware Tools.
#
# == Actions:
#
# None
#
# === Authors:
#
# Craig Watson <craig@cwatson.org>
#
# === Copyright:
#
# Copyright (C) Craig Watson
# Published under the Apache License v2.0
#
class vmwaretools::params {

  # If nothing is installed, deploy.
  if $::vmwaretools_version == 'not installed' {
    $deploy_files = true
  } else {

    # Do not deploy if the Puppet version is lower than the installed version
    if $vmwaretools::prevent_downgrade == true {
      if versioncmp($vmwaretools::version,$::vmwaretools_version) < 0 {
        $deploy_files = false
      }
    }

    # Do not deploy if the Puppet version is higher than the installed version
    if $vmwaretools::prevent_upgrade == true {
      if versioncmp($vmwaretools::version,$::vmwaretools_version) > 0 {
        $deploy_files = false
      }
    }

    # If tools are installed and we're not preventing a downgrade or upgrade, deploy on version mismatch
    if ($vmwaretools::prevent_downgrade == false) and ($vmwaretools::prevent_upgrade == false)  {
      if $::vmwaretools_version == $vmwaretools::version {
        $deploy_files = false
      } else {
        $deploy_files = true
      }
    }
  }

  $awk_path = $::osfamily ? {
    'RedHat' => '/bin/awk',
    'Debian' => '/usr/bin/awk',
    default  => '/usr/bin/awk',
  }

  if $vmwaretools::force_install == true {
    $install_command = "echo 'yes' | ${vmwaretools::working_dir}/vmware-tools-distrib/vmware-install.pl"
  } else {
    $install_command = "${vmwaretools::working_dir}/vmware-tools-distrib/vmware-install.pl -d"
  }

  # Workaround for 'purge' bug on RH-based systems
  # https://projects.puppetlabs.com/issues/2833
  # https://projects.puppetlabs.com/issues/11450
  # https://tickets.puppetlabs.com/browse/PUP-1198
  $purge_package_ensure = $::osfamily ? {
    'RedHat' => absent,
    'Suse'   => absent,
    default  => purged,
  }

  if $::osfamily == 'RedHat' and $::lsbmajdistrelease == '5' {
    if ('PAE' in $::kernelrelease) {
      $kernel_extension = regsubst($::kernelrelease, 'PAE$', '')
      $redhat_devel_package = "kernel-PAE-devel-${kernel_extension}"
    } elsif ('xen' in $::kernelrelease) {
      $kernel_extension = regsubst($::kernelrelease, 'xen$', '')
      $redhat_devel_package = "kernel-xen-devel-${kernel_extension}"
    } else {
      $redhat_devel_package = "kernel-devel-${::kernelrelease}"
    }
  } else {
    $redhat_devel_package = "kernel-devel-${::kernelrelease}"
  }

  $purge_package_list = [ 'open-vm-dkms', 'vmware-tools-services',
                          'vmware-tools-foundation', 'open-vm-tools-desktop',
                          'open-vm-source', 'open-vm-toolbox', 'open-vm-tools',
                          'open-vm-tools-dbg', 'open-vm-tools-gui', 'vmware-kmp-debug',
                          'vmware-kmp-default', 'vmware-kmp-pae', 'vmware-kmp-trace',
                          'vmware-guest-kmp-debug', 'vmware-guest-kmp-default',
                          'vmware-guest-kmp-desktop', 'vmware-guest-kmp-pae',
                          'libvmtools-devel', 'libvmtools0' ]
}
