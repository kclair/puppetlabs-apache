require 'spec_helper'

describe 'apache::vhost', :type => :define do
  let :pre_condition do
    'class { "apache": default_vhost => false, }'
  end
  let :title do
    'rspec.example.com'
  end
  let :default_params do
    {
      :docroot => '/rspec/docroot',
      :port    => '84',
    }
  end
  describe 'os-dependent items' do
    context "on RedHat based systems" do
      let :default_facts do
        {
          :osfamily               => 'RedHat',
          :operatingsystemrelease => '6',
          :concat_basedir         => '/dne',
        }
      end
      let :params do default_params end
      let :facts do default_facts end
      it { should include_class("apache") }
      it { should include_class("apache::params") }
    end
    context "on Debian based systems" do
      let :default_facts do
        {
          :osfamily               => 'Debian',
          :operatingsystemrelease => '6',
          :concat_basedir         => '/dne',
        }
      end
      let :params do default_params end
      let :facts do default_facts end
      it { should include_class("apache") }
      it { should include_class("apache::params") }
      it { should contain_file("25-rspec.example.com.conf").with(
        :ensure => 'present',
        :path   => '/etc/apache2/sites-available/25-rspec.example.com.conf'
      ) }
      it { should contain_file("25-rspec.example.com.conf symlink").with(
        :ensure => 'link',
        :path   => '/etc/apache2/sites-enabled/25-rspec.example.com.conf',
        :target => '/etc/apache2/sites-available/25-rspec.example.com.conf'
      ) }
    end
    context "on FreeBSD systems" do
      let :default_facts do
        {
          :osfamily               => 'FreeBSD',
          :operatingsystemrelease => '9',
          :concat_basedir         => '/dne',
        }
      end
      let :params do default_params end
      let :facts do default_facts end
      it { should include_class("apache") }
      it { should include_class("apache::params") }
      it { should contain_file("25-rspec.example.com.conf").with(
        :ensure => 'present',
        :path   => '/usr/local/etc/apache22/Vhosts/25-rspec.example.com.conf'
      ) }
    end
  end
  describe 'os-independent items' do
    let :facts do
      {
        :osfamily               => 'Debian',
        :operatingsystemrelease => '6',
        :concat_basedir         => '/dne',
      }
    end
    describe 'basic assumptions' do
      let :params do default_params end
      it { should include_class("apache") }
      it { should include_class("apache::params") }
      it { should contain_apache__listen(params[:port]) }
      it { should contain_apache__namevirtualhost("*:#{params[:port]}") }
    end

    # All match and notmatch should be a list of regexs and exact match strings
    context ".conf content" do
      [
        {
          :title => 'should contain docroot',
          :attr  => 'docroot',
          :value => '/not/default',
          :match => [/^  DocumentRoot \/not\/default$/,/  <Directory \/not\/default>/],
        },
        {
          :title => 'should set a port',
          :attr  => 'port',
          :value => '8080',
          :match => [/^<VirtualHost \*:8080>$/],
        },
        {
          :title => 'should set an ip',
          :attr  => 'ip',
          :value => '10.0.0.1',
          :match => [/^<VirtualHost 10\.0\.0\.1:84>$/],
        },
        {
          :title => 'should set a serveradmin',
          :attr  => 'serveradmin',
          :value => 'test@test.com',
          :match => [/^  ServerAdmin test@test.com$/],
        },
        {
          :title => 'should enable ssl',
          :attr  => 'ssl',
          :value => true,
          :match => [/^  SSLEngine on$/],
        },
        {
          :title => 'should set a servername',
          :attr  => 'servername',
          :value => 'param.test',
          :match => [/^  ServerName param.test$/],
        },
        {
          :title => 'should accept server aliases',
          :attr  => 'serveraliases',
          :value => ['one.com','two.com'],
          :match => [
            /^  ServerAlias one\.com$/,
            /^  ServerAlias two\.com$/
          ],
        },
        {
          :title => 'should accept setenv',
          :attr  => 'setenv',
          :value => ['TEST1 one','TEST2 two'],
          :match => [
            /^  SetEnv TEST1 one$/,
            /^  SetEnv TEST2 two$/
          ],
        },
        {
          :title => 'should accept setenvif',
          :attr  => 'setenvif',
          ## These are bugged in rspec-puppet; the $1 is droped
          #:value => ['Host "^([^\.]*)\.website\.com$" CLIENT_NAME=$1'],
          #:match => ['  SetEnvIf Host "^([^\.]*)\.website\.com$" CLIENT_NAME=$1'],
          :value => ['Host "^test\.com$" VHOST_ACCESS=test'],
          :match => [/^  SetEnvIf Host "\^test\\.com\$" VHOST_ACCESS=test$/],
        },
        {
          :title => 'should accept options',
          :attr  => 'options',
          :value => ['Fake','Options'],
          :match => [/^    Options Fake Options$/],
        },
        {
          :title => 'should accept overrides',
          :attr  => 'override',
          :value => ['Fake', 'Override'],
          :match => [/^    AllowOverride Fake Override$/],
        },
        {
          :title => 'should accept logroot',
          :attr  => 'logroot',
          :value => '/fake/log',
          :match => [/CustomLog \/fake\/log\//,/ErrorLog \/fake\/log\//],
        },
        {
          :title => 'should accept pipe destination for access log',
          :attr  => 'access_log_pipe',
          :value => '| /bin/fake/logging',
          :match => [/CustomLog "| \/bin\/fake\/logging" combined$/],
        },
        {
          :title => 'should accept pipe destination for error log',
          :attr  => 'error_log_pipe',
          :value => '| /bin/fake/logging',
          :match => [/ErrorLog "| \/bin\/fake\/logging" combined$/],
        },
        {
          :title => 'should accept syslog destination for access log',
          :attr  => 'access_log_syslog',
          :value => 'syslog:local1',
          :match => [/CustomLog syslog:local1 combined$/],
        },
        {
          :title => 'should accept syslog destination for error log',
          :attr  => 'error_log_syslog',
          :value => 'syslog',
          :match => [/ErrorLog syslog$/],
        },
        {
          :title => 'should accept custom format for access logs',
          :attr  => 'access_log_format',
          :value => '%h %{X-Forwarded-For}i %l %u %t \"%r\" %s %b  \"%{Referer}i\" \"%{User-agent}i\" \"Host: %{Host}i\" %T %D',
          :match => [/CustomLog \/var\/log\/.+_access\.log "%h %\{X-Forwarded-For\}i %l %u %t \\"%r\\" %s %b  \\"%\{Referer\}i\\" \\"%\{User-agent\}i\\" \\"Host: %\{Host\}i\\" %T %D"$/],
        },
        {
          :title => 'should contain access logs',
          :attr  => 'access_log',
          :value => true,
          :match => [/CustomLog \/var\/log\/.+_access\.log combined$/],
        },
        {
          :title    => 'should not contain access logs',
          :attr     => 'access_log',
          :value    => false,
          :notmatch => [/CustomLog \/var\/log\/.+_access\.log combined$/],
        },
        {
          :title => 'should contain error logs',
          :attr  => 'error_log',
          :value => true,
          :match => [/ErrorLog.+$/],
        },
        {
          :title    => 'should not contain error logs',
          :attr     => 'error_log',
          :value    => false,
          :notmatch => [/ErrorLog.+$/],
        },
        {
          :title => 'should accept a scriptalias',
          :attr  => 'scriptalias',
          :value => '/usr/scripts',
          :match => [
            /^  ScriptAlias \/cgi-bin\/ \/usr\/scripts\/$/,
            /^  <Directory \/usr\/scripts>$/,
          ],
        },
        {
          :title    => 'should accept a single scriptaliases',
          :attr     => 'scriptaliases',
          :value    => { 'alias' => '/blah/', 'path' => '/usr/scripts' },
          :match    => [
            /^  ScriptAlias \/blah\/ \/usr\/scripts\/$/,
            /^  <Directory \/usr\/scripts>$/,
          ],
          :nomatch  => [/ScriptAlias \/cgi\-bin\//],
        },
        {
          :title    => 'should accept multiple scriptaliases',
          :attr     => 'scriptaliases',
          :value    => [ { 'alias' => '/blah/', 'path' => '/usr/scripts' }, { 'alias' => '/blah2/', 'path' => '/usr/scripts' } ],
          :match    => [
            /^  ScriptAlias \/blah\/ \/usr\/scripts\/$/,
            /^  ScriptAlias \/blah2\/ \/usr\/scripts\/$/,
            /^  <Directory \/usr\/scripts>$/,
          ],
          :nomatch  => [/ScriptAlias \/cgi\-bin\//],
        },
        {
          :title    => 'should accept proxy destinations',
          :attr     => 'proxy_dest',
          :value    => 'http://fake.com',
          :match    => [
            /^  ProxyPass          \/ http:\/\/fake.com\/$/,
            /^  <Location          \/>$/,
            /^    ProxyPassReverse \/$/,
            /^  <\/Location>$/,
          ],
          :notmatch => [/ProxyPass .+!$/],
        },
        {
          :title    => 'should accept proxy_pass hash',
          :attr     => 'proxy_pass',
          :value    => { 'path' => '/path-a', 'url' => 'http://fake.com/a/' },
          :match    => [
            /^  ProxyPass \/path-a http:\/\/fake.com\/a\/$/,
            /    ProxyPassReverse \//,
          ],
          :notmatch => [/ProxyPass .+!$/],
        },
        {
          :title    => 'should accept proxy_pass array of hash',
          :attr     => 'proxy_pass',
          :value    => [
            { 'path' => '/path-a', 'url' => 'http://fake.com/a/' },
            { 'path' => '/path-b', 'url' => 'http://fake.com/b/' },
          ],
          :match    => [
            /^  ProxyPass \/path-a http:\/\/fake.com\/a\/$/,
            /^  <Location \/path-a\/>$/,
            /^    ProxyPassReverse \/$/,
            /^  <\/Location>$/,
            /^  ProxyPass \/path-b http:\/\/fake.com\/b\/$/,
            /^  <Location \/path-b\/>$/,
            /^    ProxyPassReverse \/$/,
            /^  <\/Location>$/,
          ],
          :notmatch => [/ProxyPass .+!$/],
        },
        {
          :title => 'should enable rack',
          :attr  => 'rack_base_uris',
          :value => ['/rack1','/rack2'],
          :match => [
            /^  RackBaseURI \/rack1$/,
            /^  RackBaseURI \/rack2$/,
          ],
        },
        {
          :title => 'should accept request headers',
          :attr  => 'request_headers',
          :value => ['append something', 'unset something_else'],
          :match => [
            /^  RequestHeader append something$/,
            /^  RequestHeader unset something_else$/,
          ],
        },
        {
          :title => 'should accept rewrite rules',
          :attr  => 'rewrite_rule',
          :value => 'not a real rule',
          :match => [/^  RewriteRule not a real rule$/],
        },
        {
          :title => 'should block scm',
          :attr  => 'block',
          :value => 'scm',
          :match => [/^  <DirectoryMatch \.\*\\\.\(svn\|git\|bzr\)\/\.\*>$/],
        },
        {
          :title => 'should accept a custom fragment',
          :attr  => 'custom_fragment',
          :value => "  Some custom fragment line\n  That spans multiple lines",
          :match => [
            /^  Some custom fragment line$/,
            /^  That spans multiple lines$/,
            /^<\/VirtualHost>$/,
          ],
        },
        {
          :title => 'should accept an array of alias hashes',
          :attr  => 'aliases',
          :value => [ { 'alias' => '/', 'path' => '/var/www'} ],
          :match => [/^  Alias \/ \/var\/www$/],
        },
        {
          :title => 'should accept an alias hash',
          :attr  => 'aliases',
          :value => { 'alias' => '/', 'path' => '/var/www'},
          :match => [/^  Alias \/ \/var\/www$/],
        },
        {
          :title => 'should accept multiple aliases',
          :attr  => 'aliases',
          :value => [
            { 'alias' => '/', 'path' => '/var/www'},
            { 'alias' => '/cgi-bin', 'path' => '/var/www/cgi-bin'},
            { 'alias' => '/css', 'path' => '/opt/someapp/css'},
          ],
          :match => [
            /^  Alias \/ \/var\/www$/,
            /^  Alias \/cgi-bin \/var\/www\/cgi-bin$/,
            /^  Alias \/css \/opt\/someapp\/css$/,
          ],
        },
        {
          :title => 'should accept a suPHP_Engine',
          :attr  => 'suphp_engine',
          :value => 'on',
          :match => [/^  suPHP_Engine on$/],
        },
        {
          :title => 'should accept a wsgi script alias',
          :attr  => 'wsgi_script_aliases',
          :value => { '/' => '/var/www/myapp.wsgi'},
          :match => [/^  WSGIScriptAlias \/ \/var\/www\/myapp.wsgi$/],
        },
        {
          :title => 'should accept multiple wsgi aliases',
          :attr  => 'wsgi_script_aliases',
          :value => {
            '/wiki' => '/usr/local/wsgi/scripts/mywiki.wsgi',
            '/blog' => '/usr/local/wsgi/scripts/myblog.wsgi',
            '/'     => '/usr/local/wsgi/scripts/myapp.wsgi',
          },
          :match => [
            /^  WSGIScriptAlias \/wiki \/usr\/local\/wsgi\/scripts\/mywiki.wsgi$/,
            /^  WSGIScriptAlias \/blog \/usr\/local\/wsgi\/scripts\/myblog.wsgi$/,
            /^  WSGIScriptAlias \/ \/usr\/local\/wsgi\/scripts\/myapp.wsgi$/,
          ],
        },
        {
          :title    => 'should accept a directory',
          :attr     => 'directories',
          :value    => { 'path' => '/opt/app' },
          :notmatch => ['  <Directory /rspec/docroot>'],
          :match    => [
            /^  <Directory \/opt\/app>$/,
            /^    AllowOverride None$/,
            /^    Order allow,deny$/,
            /^    Allow from all$/,
            /^  <\/Directory>$/,
          ],
        },
        {
          :title    => 'should accept directory directives hash',
          :attr     => 'directories',
          :value    => {
            'path'              => '/opt/app',
            'headers'           => 'Set X-Robots-Tag "noindex, noarchive, nosnippet"',
            'allow'             => 'from rspec.org',
            'allow_override'    => 'Lol',
            'deny'              => 'from google.com',
            'options'           => '-MultiViews',
            'order'             => 'deny,yned',
            'passenger_enabled' => 'onf',
          },
          :match    => [
            /^  <Directory \/opt\/app>$/,
            /^    Header Set X-Robots-Tag "noindex, noarchive, nosnippet"$/,
            /^    Allow from rspec.org$/,
            /^    AllowOverride Lol$/,
            /^    Deny from google.com$/,
            /^    Options -MultiViews$/,
            /^    Order deny,yned$/,
            /^    PassengerEnabled onf$/,
            /^  <\/Directory>$/,
          ],
        },
        {
          :title    => 'should accept directory directives with arrays and hashes',
          :attr     => 'directories',
          :value    => [
            {
              'path'              => '/opt/app1',
              'allow'             => 'from rspec.org',
              'allow_override'    => ['AuthConfig','Indexes'],
              'deny'              => 'from google.com',
              'options'           => ['-MultiViews','+MultiViews'],
              'order'             => ['deny','yned'],
              'passenger_enabled' => 'onf',
            },
            {
              'path'        => '/opt/app2',
              'addhandlers' => {
                'handler'    => 'cgi-script',
                'extensions' => '.cgi',
              },
            },
          ],
          :match    => [
            /^  <Directory \/opt\/app1>$/,
            /^    Allow from rspec.org$/,
            /^    AllowOverride AuthConfig Indexes$/,
            /^    Deny from google.com$/,
            /^    Options -MultiViews \+MultiViews$/,
            /^    Order deny,yned$/,
            /^    PassengerEnabled onf$/,
            /^  <\/Directory>$/,
            /^  <Directory \/opt\/app2>$/,
            /^    AllowOverride None$/,
            /^    Order allow,deny$/,
            /^    Allow from all$/,
            /^    AddHandler cgi-script .cgi$/,
            /^  <\/Directory>$/,
          ],
        },
        {
          :title    => 'should accept multiple directories',
          :attr     => 'directories',
          :value    => [
            { 'path' => '/opt/app' },
            { 'path' => '/var/www' },
            { 'path' => '/rspec/docroot'}
          ],
          :match    => [
            /^  <Directory \/opt\/app>$/,
            /^  <Directory \/var\/www>$/,
            /^  <Directory \/rspec\/docroot>$/,
          ],
        },
        {
          :title => 'should accept location for provider',
          :attr  => 'directories',
          :value => {
            'path'     => '/',
            'provider' => 'location',
          },
          :notmatch => ['    AllowOverride None'],
          :match => [
            /^  <Location \/>$/,
            /^    Order allow,deny$/,
            /^    Allow from all$/,
            /^  <\/Location>$/,
          ],
        },
        {
          :title => 'should accept files for provider',
          :attr  => 'directories',
          :value => {
            'path'     => 'index.html',
            'provider' => 'files',
          },
          :notmatch => ['    AllowOverride None'],
          :match => [
            /^  <Files index.html>$/,
            /^    Order allow,deny$/,
            /^    Allow from all$/,
            /^  <\/Files>$/,
          ],
        },
        {
          :title => 'should contain virtual_docroot',
          :attr  => 'virtual_docroot',
          :value => '/not/default',
          :match => [
            /^  VirtualDocumentRoot \/not\/default$/,
          ],
        },

      ].each do |param|
        describe "when #{param[:attr]} is #{param[:value]}" do
          let :params do default_params.merge({ param[:attr].to_sym => param[:value] }) end

          it { should contain_file("25-#{title}.conf").with_mode('0644') }
          if param[:match]
            it "#{param[:title]}: matches" do
              param[:match].each do |match|
                should contain_file("25-#{title}.conf").with_content( match )
              end
            end
          end
          if param[:notmatch]
            it "#{param[:title]}: notmatches" do
              param[:notmatch].each do |notmatch|
                should_not contain_file("25-#{title}.conf").with_content( notmatch )
              end
            end
          end
        end
      end
    end

    context ".conf content with SSL" do
      [
        {
            :title => 'should accept setting SSLCertificateFile',
            :attr  => 'ssl_cert',
            :value => '/path/to/cert.pem',
            :match => [/^  SSLCertificateFile      \/path\/to\/cert\.pem$/],
        },
        {
            :title => 'should accept setting SSLCertificateKeyFile',
            :attr  => 'ssl_key',
            :value => '/path/to/cert.pem',
            :match => [/^  SSLCertificateKeyFile   \/path\/to\/cert\.pem$/],
        },
        {
            :title => 'should accept setting SSLCertificateChainFile',
            :attr  => 'ssl_chain',
            :value => '/path/to/cert.pem',
            :match => [/^  SSLCertificateChainFile \/path\/to\/cert\.pem$/],
        },
        {
            :title => 'should accept setting SSLCertificatePath',
            :attr  => 'ssl_certs_dir',
            :value => '/path/to/certs',
            :match => [/^  SSLCACertificatePath    \/path\/to\/certs$/],
        },
        {
            :title => 'should accept setting SSLCertificateFile',
            :attr  => 'ssl_ca',
            :value => '/path/to/ca.pem',
            :match => [/^  SSLCACertificateFile    \/path\/to\/ca\.pem$/],
        },
        {
            :title => 'should accept setting SSLRevocationPath',
            :attr  => 'ssl_crl_path',
            :value => '/path/to/crl',
            :match => [/^  SSLCARevocationPath     \/path\/to\/crl$/],
        },
        {
            :title => 'should accept setting SSLRevocationFile',
            :attr  => 'ssl_crl',
            :value => '/path/to/crl.pem',
            :match => [/^  SSLCARevocationFile     \/path\/to\/crl\.pem$/],
        },
        {
            :title => 'should accept setting SSLProxyEngine',
            :attr  => 'ssl_proxyengine',
            :value => true,
            :match => [/^  SSLProxyEngine On$/],
        },
        {
            :title => 'should accept setting SSLProtocol',
            :attr  => 'ssl_protocol',
            :value => 'all -SSLv2',
            :match => [/^  SSLProtocol             all -SSLv2$/],
        },
        {
            :title => 'should accept setting SSLCipherSuite',
            :attr  => 'ssl_cipher',
            :value => 'RC4-SHA:HIGH:!ADH:!SSLv2',
            :match => [/^  SSLCipherSuite          RC4-SHA:HIGH:!ADH:!SSLv2$/],
        },
        {
            :title => 'should accept setting SSLHonorCipherOrder',
            :attr  => 'ssl_honorcipherorder',
            :value => 'On',
            :match => [/^  SSLHonorCipherOrder     On$/],
        },
        {
            :title => 'should accept setting SSLVerifyClient',
            :attr  => 'ssl_verify_client',
            :value => 'optional',
            :match => [/^  SSLVerifyClient         optional$/],
        },
        {
            :title => 'should accept setting SSLVerifyDepth',
            :attr  => 'ssl_verify_depth',
            :value => '1',
            :match => [/^  SSLVerifyDepth          1$/],
        },
        {
            :title => 'should accept setting SSLOptions with a string',
            :attr  => 'ssl_options',
            :value => '+ExportCertData',
            :match => [/^  SSLOptions \+ExportCertData$/],
        },
        {
            :title => 'should accept setting SSLOptions with an array',
            :attr  => 'ssl_options',
            :value => ['+StdEnvVars','+ExportCertData'],
            :match => [/^  SSLOptions \+StdEnvVars \+ExportCertData/],
        },
      ].each do |param|
        describe "when #{param[:attr]} is #{param[:value]} with SSL" do
          let :params do
            default_params.merge( {
              param[:attr].to_sym => param[:value],
              :ssl                => true,
            } )
          end
          it { should contain_file("25-#{title}.conf").with_mode('0644') }
          if param[:match]
            it "#{param[:title]}: matches" do
              param[:match].each do |match|
                should contain_file("25-#{title}.conf").with_content( match )
              end
            end
          end
          if param[:notmatch]
            it "#{param[:title]}: notmatches" do
              param[:notmatch].each do |notmatch|
                should_not contain_file("25-#{title}.conf").with_content( notmatch )
              end
            end
          end
        end
      end
    end

    context 'attribute resources' do
      describe 'when access_log_file and access_log_pipe are specified' do
        let :params do default_params.merge({
          :access_log_file => 'fake.log',
          :access_log_pipe => '| /bin/fake',
        }) end
        it 'should cause a failure' do
          expect { subject }.to raise_error(Puppet::Error, /'access_log_file' and 'access_log_pipe' cannot be defined at the same time/)
        end
      end
      describe 'when error_log_file and error_log_pipe are specified' do
        let :params do default_params.merge({
          :error_log_file => 'fake.log',
          :error_log_pipe => '| /bin/fake',
        }) end
        it 'should cause a failure' do
          expect { subject }.to raise_error(Puppet::Error, /'error_log_file' and 'error_log_pipe' cannot be defined at the same time/)
        end
      end
      describe 'when docroot owner is specified' do
        let :params do default_params.merge({
          :docroot_owner => 'testuser',
          :docroot_group => 'testgroup',
        }) end
        it 'should set vhost ownership' do
          should contain_file(params[:docroot]).with({
            :ensure => :directory,
            :owner  => 'testuser',
            :group  => 'testgroup',
          })
        end
      end

      describe 'when wsgi_daemon_process and wsgi_daemon_process_options are specified' do
        let :params do default_params.merge({
          :wsgi_daemon_process         => 'example.org',
          :wsgi_daemon_process_options => { 'processes' => '2', 'threads' => '15' },
        }) end
        it 'should set wsgi_daemon_process_options' do
          should contain_file("25-#{title}.conf").with_content(
            /^  WSGIDaemonProcess example.org processes=2 threads=15$/
          )
        end
      end

      describe 'when rewrite_rule and rewrite_cond are specified' do
        let :params do default_params.merge({
          :rewrite_cond => '%{HTTPS} off',
          :rewrite_rule => '(.*) https://%{HTTPS_HOST}%{REQUEST_URI}',
        }) end
        it 'should set RewriteCond' do
          should contain_file("25-#{title}.conf").with_content(
            /^  RewriteCond %\{HTTPS\} off$/
          )
        end
      end

      describe 'when suphp_engine is on and suphp_configpath is specified' do
        let :params do default_params.merge({
          :suphp_engine     => 'on',
          :suphp_configpath => '/etc/php5/apache2',
        }) end
        it 'should set suphp_configpath' do
          should contain_file("25-#{title}.conf").with_content(
            /^  suPHP_ConfigPath \/etc\/php5\/apache2$/
          )
        end
      end

      describe 'when suphp_engine is on and suphp_addhandler is specified' do
        let :params do default_params.merge({
          :suphp_engine     => 'on',
          :suphp_addhandler => 'x-httpd-php',
        }) end
        it 'should set suphp_addhandler' do
          should contain_file("25-#{title}.conf").with_content(
            /^  suPHP_AddHandler x-httpd-php/
          )
        end
      end

      describe 'priority/default settings' do
        describe 'when neither priority/default is specified' do
          let :params do default_params end
          it { should contain_file("25-#{title}.conf").with_path(
            /25-#{title}.conf/
          ) }
        end
        describe 'when both priority/default_vhost is specified' do
          let :params do
            default_params.merge({
              :priority      => 15,
              :default_vhost => true,
            })
          end
          it { should contain_file("15-#{title}.conf").with_path(
            /15-#{title}.conf/
          ) }
        end
        describe 'when only priority is specified' do
          let :params do
            default_params.merge({ :priority => 14, })
          end
          it { should contain_file("14-#{title}.conf").with_path(
            /14-#{title}.conf/
          ) }
        end
        describe 'when only default is specified' do
          let :params do
            default_params.merge({ :default_vhost => true, })
          end
          it { should contain_file("10-#{title}.conf").with_path(
            /10-#{title}.conf/
          ) }
        end
      end

      describe 'various ip/port combos' do
        describe 'when ip_based is true' do
          let :params do default_params.merge({ :ip_based => true }) end
          it 'should not specify a NameVirtualHost' do
            should contain_apache__listen(params[:port])
            should_not contain_apache__namevirtualhost("*:#{params[:port]}")
          end
        end

        describe 'when ip_based is default' do
          let :params do default_params end
          it 'should specify a NameVirtualHost' do
            should contain_apache__listen(params[:port])
            should contain_apache__namevirtualhost("*:#{params[:port]}")
          end
        end

        describe 'when an ip is set' do
          let :params do default_params.merge({ :ip => '10.0.0.1' }) end
          it 'should specify a NameVirtualHost for the ip' do
            should_not contain_apache__listen(params[:port])
            should contain_apache__listen("10.0.0.1:#{params[:port]}")
            should contain_apache__namevirtualhost("10.0.0.1:#{params[:port]}")
          end
        end

        describe 'an ip_based vhost without a port' do
          let :params do
            {
              :docroot  => '/fake',
              :ip       => '10.0.0.1',
              :ip_based => true,
            }
          end
          it 'should specify a NameVirtualHost for the ip' do
            should_not contain_apache__listen(params[:ip])
            should_not contain_apache__namevirtualhost(params[:ip])
            should contain_file("25-#{title}.conf").with_content %r{<VirtualHost 10\.0\.0\.1>}
          end
        end
      end

      describe 'redirect rules' do
        describe 'without lockstep arrays' do
          let :params do
            default_params.merge({
              :redirect_source => [
                '/login',
                '/logout',
              ],
              :redirect_dest   => [
                'http://10.0.0.10/login',
                'http://10.0.0.10/logout',
              ],
              :redirect_status   => [
                'permanent',
                '',
              ],
            })
          end

          it { should contain_file("25-#{title}.conf").with_content %r{  Redirect permanent /login http://10\.0\.0\.10/login} }
          it { should contain_file("25-#{title}.conf").with_content %r{  Redirect  /logout http://10\.0\.0\.10/logout} }
        end
        describe 'without a status' do
          let :params do
            default_params.merge({
              :redirect_source => [
                '/login',
                '/logout',
              ],
              :redirect_dest   => [
                'http://10.0.0.10/login',
                'http://10.0.0.10/logout',
              ],
            })
          end

          it { should contain_file("25-#{title}.conf").with_content %r{  Redirect  /login http://10\.0\.0\.10/login} }
          it { should contain_file("25-#{title}.conf").with_content %r{  Redirect  /logout http://10\.0\.0\.10/logout} }
        end
        describe 'with a single status and dest' do
          let :params do
            default_params.merge({
              :redirect_source => [
                '/login',
                '/logout',
              ],
              :redirect_dest   => 'http://10.0.0.10/test',
              :redirect_status => 'permanent',
            })
          end

          it { should contain_file("25-#{title}.conf").with_content %r{  Redirect permanent /login http://10\.0\.0\.10/test} }
          it { should contain_file("25-#{title}.conf").with_content %r{  Redirect permanent /logout http://10\.0\.0\.10/test} }
        end

        describe 'with a directoryindex specified' do
          let :params do
            default_params.merge({
              :directoryindex => 'index.php'
            })
          end
          it { should contain_file("25-#{title}.conf").with_content %r{DirectoryIndex index.php} }
	end
      end
    end
  end
end
