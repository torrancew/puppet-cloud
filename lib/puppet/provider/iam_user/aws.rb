require_relative '../../../puppet_x/cloud/aws'

Puppet::Type.type(:iam_user).provide(:aws) do
  include PuppetX::Cloud::AWS
  service :iam

  def self.instances
    api_object = iam('list-users')

    api_object['Users'].map do |user|
      new({
        :name   => user['UserName'],
        :ensure => :present,
      })
    end
  end

  def create
    iam('create-user', 'user-name' => resource[:name])
    @property_hash[:ensure] = :present
  end

  def destroy
    iam('delete-user', 'user-name' => resource[:name])
    @property_hash[:ensure] = :absent
  end
end
