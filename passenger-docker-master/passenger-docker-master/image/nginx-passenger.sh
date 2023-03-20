#!/bin/bash
set -e
source /pd_build/buildconfig
source /etc/environment

header "Installing Phusion Passenger..."

## Phusion Passenger requires Ruby. Install it through RVM, not APT,
## so that the -customizable variant cannot end up having Ruby installed
## from both APT and RVM.
if [[ ! -e /usr/bin/ruby ]]; then
	run /pd_build/ruby_support/prepare.sh
	run /usr/local/rvm/bin/rvm install ruby-3.1.3
	# Make passenger_system_ruby work.
	run create_rvm_wrapper_script ruby3.1 ruby-3.1.3 ruby
	run /pd_build/ruby_support/finalize.sh
fi

## Install Phusion Passenger.
if [[ "$PASSENGER_ENTERPRISE" ]]; then
	run apt-get install -y nginx passenger-enterprise libnginx-mod-http-passenger-enterprise
else
	run apt-get install -y nginx passenger libnginx-mod-http-passenger
fi
run cp /pd_build/config/30_presetup_nginx.sh /etc/my_init.d/
run cp /pd_build/config/nginx.conf /etc/nginx/nginx.conf
run mkdir -p /etc/nginx/main.d
run cp /pd_build/config/nginx_main_d_default.conf /etc/nginx/main.d/default.conf

## Install Nginx runit service.
run mkdir /etc/service/nginx
run cp /pd_build/runit/nginx /etc/service/nginx/run
run touch /etc/service/nginx/down

run mkdir /etc/service/nginx-log-forwarder
run cp /pd_build/runit/nginx-log-forwarder /etc/service/nginx-log-forwarder/run

run mkdir /var/run/passenger-instreg

run sed -i 's|invoke-rc.d nginx rotate|sv 1 nginx|' /etc/logrotate.d/nginx
run sed -i -e '/sv 1 nginx.*/a\' -e '		passenger-config reopen-logs >/dev/null 2>&1' /etc/logrotate.d/nginx

## Precompile Ruby extensions.
if [[ -e /usr/bin/ruby3.2 ]]; then
	run ruby3.2 -S passenger-config build-native-support
	run setuser app ruby3.2 -S passenger-config build-native-support
fi
if [[ -e /usr/bin/ruby3.1 ]]; then
	run ruby3.1 -S passenger-config build-native-support
	run setuser app ruby3.1 -S passenger-config build-native-support
fi
if [[ -e /usr/bin/ruby3.0 ]]; then
	run ruby3.0 -S passenger-config build-native-support
	run setuser app ruby3.0 -S passenger-config build-native-support
fi
if [[ -e /usr/bin/ruby2.7 ]]; then
	run ruby2.7 -S passenger-config build-native-support
	run setuser app ruby2.7 -S passenger-config build-native-support
fi
if [[ -e /usr/bin/jruby9.4 ]]; then
	run jruby9.4 --dev -S passenger-config build-native-support
	run setuser app jruby9.4 -S passenger-config build-native-support
fi
if [[ -e /usr/bin/jruby9.3 ]]; then
	run jruby9.3 --dev -S passenger-config build-native-support
	run setuser app jruby9.3 -S passenger-config build-native-support
fi
