require_relative '../../../puppet_x/cloud/aws'

Puppet::Type.type(:subnet).provide(:aws) do
  include PuppetX::Cloud::AWS
  service :ec2

  def self.instances
    api_object = ec2('describe-subnets')

    api_object['Subnets'].map do |subnet|
      tags = {}
      (subnet['Tags'] || {}).each do |t|
        tags[t['Key']] = t['Value']
      end

      new({
        :name     => (tags['Name'] || subnet['VpcId']),
        :ensure   => (subnet['State'] == 'terminated' ? :absent : :present),
        :cidr     => subnet['CidrBlock'],
        :metadata => tags.reject{ |k, _| k == 'Name' },
        :vpc      => subnet['VpcId'],
      })
    end
  end

  def create
    subnet = ec2('create-subnet', 'cidr-block' => resource[:cidr], 'vpc-id' => resource[:vpc])
    tag(subnet['Subnet']['SubnetId'], (resource[:metadata] || {}).merge({'Name': resource[:name]}))
    @property_hash[:ensure] = :present
  end

  def destroy
    ec2('delete-subnet', 'subnet-id' => resource_id)
    @property_hash[:ensure] = :absent
  end

  def resource_id
    subnets = ec2('describe-subnets', 'filters' => "Name=tag:Name,Values=#{resource[:name]}")
    subnets['Subnets'].map{ |subnet| subnet['SubnetId'] }.first
  end
end
