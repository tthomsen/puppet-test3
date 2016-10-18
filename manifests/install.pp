# == Class test::install
#
# This class is called from test for install.
#
class test::install {

  package { $::test::package_name:
    ensure => present,
  }
}
