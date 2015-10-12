#!/bin/bash

chef gem install knife-solo
#chef gem install knife-zero

vagrant plugin install vagrant-omnibus

bundle init

cat <<EOF >> Gemfile
gem 'chef' , '11.12.4'
gem 'knife-solo'
gem 'berkshelf', '3.1.2'
EOF

bundle install --path vendor/bundler

bundle exec berks cookbook yum-pkg

cat <<EOF >> yum-pkg/recipes/default.rb
%w[openssl openssl-devel sqlite sqlite-devel].each do |pkg|
    package pkg do
        action :install
    end
end
EOF

cat <<EOF > Berksfile
source 'https://api.berkshelf.com'

cookbook 'yum-pkg', path: 'yum-pkg'

cookbook 'git'
cookbook 'build-essential'
cookbook 'yum', '~> 3.2.4'
cookbook 'vim', '~> 1.1.2'
cookbook 'openssl', '~> 2.0.0'
cookbook 'nginx', '~> 2.7.4'
cookbook 'unicorn', '~> 2.0.0'
cookbook 'rbenv', :git => 'git://github.com/fnichol/chef-rbenv.git', :branch => 'v0.7.2'
cookbook 'ruby_build', '~> 0.8.0'
cookbook 'emacs24'
cookbook 'tmux'
EOF

bundle exec berks vendor cookbooks

cat << EOF > Vagrantfile
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    config.vm.box = "yourbox"

# Chef最新版をインストール（omnibus）
config.omnibus.chef_version = :latest

config.vm.provision :chef_solo do |chef|


    chef.cookbooks_path = "./cookbooks"
chef.run_list = [
    'recipe[yum-pkg]'
]
chef.add_recipe 'yum'
chef.add_recipe 'build-essential'
chef.add_recipe 'ruby_build'
chef.add_recipe 'rbenv::system'
chef.add_recipe 'git'
chef.add_recipe 'vim'
chef.add_recipe 'nginx'
chef.add_recipe 'unicorn'
chef.add_recipe 'emasc24'
chef.add_recipe 'tmux'

# Ruby2.1.2をインストール
chef.json = {
    "rbenv" => {
	"global" => "2.1.2",
	"rubies" => [ "2.1.2" ],
	"gems" => {
	    "2.1.2" => [
		{ 'name' => 'bundler' }
	    ]
	}
    }
}
end
end
EOF

vagrant up
