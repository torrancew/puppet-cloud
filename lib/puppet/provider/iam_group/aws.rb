require_relative '../../../puppet_x/cloud/aws'

Puppet::Type.type(:iam_group).provide(:aws) do
  include PuppetX::Cloud::AWS
  service :iam

  def self.instances
    api_object = iam('list-groups')

    api_object['Groups'].map do |group|
      new({
        :name   => group['GroupName'],
        :ensure => :present,
      })
    end
  end

  def create
    iam('create-group', 'group-name' => resource[:name])
    @property_hash[:ensure] = :present
  end

  def destroy
    iam('delete-group', 'group-name' => resource[:name])
    @property_hash[:ensure] = :absent
  end
end
