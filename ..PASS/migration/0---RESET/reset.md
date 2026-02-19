
RECREATE ALL MIGRATIONS

1) Delete all migration files
   
    rm -rf db/migrate/*
    rm db/structure.sql


    mise use -g ruby@3.4.7


2) Re-generate framework migrations
    
    bin/rails active_storage:install
    
    bin/rails generate doorkeeper:install
      or 
    bin/rails generate doorkeeper:migration
    

3) Re-create your own domain migrations

    bin/rails generate migration CreateUsers
    bin/rails generate migration CreateRoles
    bin/rails generate migration CreateUserRoles
    bin/rails generate migration CreateSessions

    
4) Now run the reset

    in a container terminal
        bin/rails db:drop db:create db:migrate

