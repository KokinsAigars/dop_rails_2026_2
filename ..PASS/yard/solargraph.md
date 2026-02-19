
    gem 'solargraph', '~> 0.58.2'
    bundle exec yard gems

To help IntelliJ see these methods, you need to generate YARD sticks (documentation) that the IDE can read.
Install the solargraph gem: This is a language server that "guesses" Rails magic better than the default IntelliJ indexer.
Use the base-api generator: Run bundle exec yard gems in your terminal. This builds a map of all your gems so IntelliJ can at least find the parts that belong to Rails.

after that in the terminal or in a docker container: and in the second terminal rebuild documentation:

    bundle exec yard server --reload
    bundle exec yard doc

Listening on http://0.0.0.0:8808





rails c
method_info = ApplicationController.instance_method(:current_user).source_location
puts method_info.inspect

if it returns nil, the method is written in C (internal Ruby). If it returns a path, that is your "Aha!" moment.


4. How to tell "Who wrote what?"
   Method Name,                        Usually belongs to...
   "params, session, flash",           Rails Core (ActionController)
   "current_user, authenticate_user!", Authentication System (Devise or your Concern)
   "notify, cleanup_flashes",          You (ApplicationController)
   "save, update, where",              ActiveRecord (The Database)

if in docker container: add ports: - "8808:8808" # YARD documentation server
docker ps (and look for , 0.0.0.0:8808->8808/tcp, [::]:8808->8808/tcp)



What you get: A searchable interface of every class and method. If you click on a method, it will show you the source code and the file path, even for methods inside gems!

The --reload flag: This is key—it tells YARD to update the docs instantly if you change your code.


2. For IntelliJ: Connecting the Dots
   IntelliJ (and RubyMine) doesn't automatically "see" the YARD docs unless it knows where to look.

Index the Docs: IntelliJ usually notices the .yardoc folder you created. If it doesn't, go to File > Invalidate Caches... and restart. This forces the IDE to re-scan the project including the new documentation.

External Libraries: Look at your project tree in IntelliJ under External Libraries. Because you ran yard gems, you should now be able to Ctrl + Click (or Cmd + Click) on many Rails methods that were previously "dead links."


HOW TO USE YARD
# Assigns roles to a user, ensuring self-demotion is prevented.
#
# @param user [User] the user instance to modify
# @return [void]
def assign_roles!(user)
# ...
end

by adding comments like this, YARD will be able to parse the method and display it in the documentation.





in I want to see the source code of the Rails specific methods.
    
    bundle exec yard gems



return types
    rails c
    u = User.first
    u.label.class
    # => String
    
    u.notification_enabled?(:test).class
    # => TrueClass (which is a Boolean)


If a method can return two different things (like a String OR nil), YARD lets you document that too: 
# @return [String, nil]

Hash.new (or {}) is a collection of Key-Value pairs.
so if returning {} it's a Hash,
    irb> {}.class
    => Hash
    
    irb> {}.is_a?(Object)
    => true


Important: puts vs Rails.logger
puts: Prints only to the STDOUT (your terminal window). It's great for quick "is this working?" checks.

Rails.logger: Prints to your log file (logs/development.log). This is better for long-term debugging because you can look back at what happened.


rm log/development.log
bin/rails log:clear



