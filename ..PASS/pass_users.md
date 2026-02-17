
    kokins.aigars@gmail.com
    aigars@buvprojekti.lv
    S349834KLkhewe09234dflk.

    MINIO_ROOT_USER=minioadmin
    MINIO_ROOT_PASSWORD=minioadmin123
    INIO_ROOT_PASSWORD=S349834KLkhewe09234dflk.
    MINIO_VOLUMES="/mnt/minio_data"
    MINIO_OPTS="--console-address :9001"
        
        sudo systemctl status minio
        sudo systemctl daemon-reload
        sudo systemctl enable minio
        sudo systemctl start minio



{
"notifications": {
"success": false
},
"ui": {
"layout": "left",
"explorer_width": 300,
"theme": "dark"
}
}

    bundle exec yard server --reload
    bundle exec yard doc

Listening on http://0.0.0.0:8808


1) Create the user (console)

    bin/rails console
    
    # 1. Find the user
    u = User.find_by(email_address: "kokins.aigars@gmail.com")

    # 2. Find the actual Role record (assuming your role is named "admin")
    # Use lowercase or uppercase depending on how you stored it in your 'roles' table
    admin_role = Role.find_by!(name: "admin")

    # 3. Create the association
    UserRole.find_or_create_by!(user: u, role: admin_role)


    puts "Success: #{u.email_address} is now an admin."


    u = User.create!(
    email_address: "aigars@buvprojekti.lv",
    password: "S349834KLkhewe09234dflk.",
    password_confirmation: "S349834KLkhewe09234dflk.",
    enabled: true
    )


2) Find (or create) the “admin” role

    admin_role = Role.find_or_create_by!(name: "admin") do |r|
    r.label = "Administrator"
    r.description = "Full access"
    end

    role_user = Role.find_or_create_by!(name: "user") do |r|
    r.label = "User"
    r.description = "Regular application user"
    end


3) Assign the role to the user


    UserRole.find_or_create_by!(user: u, role: admin_role)

    UserRole.find_or_create_by!(user: u, role: role_user)


4) Verify


    u.reload.roles.pluck(:name)
# => ["admin"]
    u2.reload.roles.pluck(:name)
# => ["user"]

5) Save

    u.save!
    exit

[//]: # (update password)


    bin/rails console
    u = User.find_by(email_address: 'admin@example.com')
    u.password = "S349834KLkhewe09234dflk."
    u.password_confirmation = "S349834KLkhewe09234dflk."

    u.save!
    exit

    u = User.find_by(email_address: 'user@example.com')
    r = Role.find_or_create_by(name: "user", label: "User")
    u.user? # should return true


bin/rails console

    u = User.find_by(email_address: 'admin@example.com')
    r = Role.find_or_create_by(name: "admin", label: "Administrator")
    u.roles << r unless u.roles.include?(r)
    u.admin? # should return true


mise use -g ruby@3.4.7
bin/rails db:migrate

bin/rails db:migrate:status | tail -n 20
DELETE FROM schema_migrations
WHERE version = '20260206043908';



Phase,      Action,     Explicit Logic
Request,    create,     SecureRandom.urlsafe_base64 → DB update_columns
Email,      Mailer,     Sends https://myapp.com/passwords/TOKEN/edit
Verify,     set_user,   User.find_by(reset_password_token: params[:token])
Save,       update,     BCrypt::Password.create → DB update_columns

