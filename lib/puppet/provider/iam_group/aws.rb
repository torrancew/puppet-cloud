require_relative '../../../puppet_x/cloud/aws'

Puppet::Type.type(:iam_group).provide(:aws) do
  include PuppetX::Cloud::AWS

  def self.instances
    api_object = awscli('iam', 'list-groups')

    api_object['Groups'].map do |group|
      new({
        :name   => group['GroupName'],
        :ensure => :present,
      })
    end
  end

  def create
    awscli('iam', 'create-group', 'group-name' => resource[:name])
    @property_hash[:ensure] = :present
  end

  def destroy
    awscli('iam', 'delete-group', 'group-name' => resource[:name])
    @property_hash[:ensure] = :absent
  end
end
