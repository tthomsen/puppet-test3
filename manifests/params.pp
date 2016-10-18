# == Class test::params
#
# This class is meant to be called from test.
# It sets variables according to platform.
#
class test::params {
  case $::osfamily {
    'Debian': {
      $package_name = 'test'
      $service_name = 'test'
    }
    'RedHat', 'Amazon': {
      $package_name = 'test'
      $service_name = 'test'
    }
    default: {
      fail("${::operatingsystem} not supported")
    }
  }
}
