# Class: test
# ===========================
#
# Full description of class test here.
#
# Parameters
# ----------
#
# * `sample parameter`
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
class test (
  $package_name = $::test::params::package_name,
  $service_name = $::test::params::service_name,
) inherits ::test::params {

  # validate parameters here

  class { '::test::install': } ->
  class { '::test::config': } ~>
  class { '::test::service': } ->
  Class['::test']
}
