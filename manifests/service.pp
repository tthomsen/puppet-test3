# == Class test::service
#
# This class is meant to be called from test.
# It ensure the service is running.
#
class test::service {

  service { $::test::service_name:
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }
}
