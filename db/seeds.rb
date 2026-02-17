# frozen_string_literal: true

# rails db:seed

%w[user admin].each do |name|
  Role.find_or_create_by!(name: name)
end


# seed global config
configs = [
  { key: 'allow_flash_notifications', value: 'true' },
  { key: 'maintenance_mode',          value: 'false' },
  { key: 'registration_enabled',      value: 'true' }
]

configs.each do |config|
  GlobalConfig.find_or_create_by!(key: config[:key]) do |c|
    c.value = config[:value]
  end
end

puts "GlobalConfig seeded with #{GlobalConfig.count} settings."
