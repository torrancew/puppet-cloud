Puppet::Type.newtype(:iam_user) do
  desc 'Manage cloud IAM users'

  ensurable
  newparam(:name, :namevar => true) do
    desc 'The name of the IAM user'
  end
end
