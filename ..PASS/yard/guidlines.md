

In YARD, the @!attribute tag needs to know three things: the access level (read/write), the name of the attribute, and the type.

[rw]: Stands for "Read/Write". It tells YARD that this attribute has both a getter and a setter.

@return [String]

# @!attribute [rw] name
#   @return [String] The unique name of the role, stored in lowercase.
class Role < ApplicationRecord



When you add # frozen_string_literal: true: 
    Every string in that file becomes a constant.
    Ruby creates the string "Ghost" once and reuses that same memory address every time.
    This reduces Garbage Collection (GC) pressure, making your app faster and using less RAM.

RuboCop: If you use the RuboCop gem, it has a rule called Style/FrozenStringLiteralComment. If you run bundle exec rubocop -A, it will automatically inject that line at the top of every file in your project.

    bundle exec rubocop -A
