---
title: Basic role management
date: 2024-01-04
tags:
  - code
  - ruby
  - rails
---

Believe it or not, I don't only work on or write about SQLite, and today I want to share a simple pattern for role management in Rails inspired by the [`rolify` gem](https://github.com/RolifyCommunity/rolify). I have been using this setup in the Rails app I am currently working on, and it has been a lovely experience. I've also had to evolve the pattern a bit recently, so I thought now was a great time to share the current state of things. Let's jump into it!

<!--/summary-->

- - -

The pattern works with 3 core models and then any number of related models. The core models are (you guessed it) `User`, `Role`, and `UserRole`. The `User` model represents, well, a user of your application. The `Role` model is a role that a user can have. The `UserRole` model is the join table between the two, denoting that this particular user has this particular role.

Still taking inspiration directly from [`rolify`](https://github.com/RolifyCommunity/rolify), the `Role` model not only has a `name` but also has an optional polymorphic association to a `resource`. This gives us three different kinds of roles that we can define:

1. a "global" role,
2. a "class" role that is bound to a particular resource class, and
3. an "instance" role that is bound to a particular resource instance.

This architecture is simple yet powerful. So simple, in fact, that I don't think it is worth bringing in a dependency like `rolify` to handle it. So, I just generate these models myself:

```ruby
# /db/migrate/*_create_users.rb
class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      # this is always pretty specific to each application

      t.timestamps
    end
  end
end

# /db/migrate/*_create_roles.rb
class CreateRoles < ActiveRecord::Migration[7.1]
  def change
    create_table :roles do |t|
      t.string :name
      t.references :resource, polymorphic: true, null: true

      t.timestamps
    end
    add_index :roles, [:name, :resource_type, :resource_id], unique: true
  end
end

# /db/migrate/*_create_user_roles.rb
class CreateUserRoles < ActiveRecord::Migration[7.1]
  def change
    create_table :user_roles do |t|
      t.references :user, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true

      t.timestamps
    end
  end
end
```

The models themselves are also pretty straightforward:

```ruby
# /app/models/user.rb
class User < ApplicationRecord
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
end

# /app/models/role.rb
class Role < ApplicationRecord
  belongs_to :resource, polymorphic: true, optional: true
  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles
end

# /app/models/user_role.rb
class UserRole < ApplicationRecord
  belongs_to :user
  belongs_to :role
end
```

This basic setup is not what I wanted to share though. The core of the pattern is how we _use_ these models to define roles and then check roles to drive authorization.

- - -

For the rest of this article, we will be working in my production app. That application has `Campaign`s and `Customer`s. Here is the breakdown of the roles our system has. A `User` can be:

* a `developer`, or
* an `admin`, or
* a `manager` of `Campaign`s, or
* a `member` of a `Customer`, or
* a `manager` of a `Customer`.

So, we have two "global" roles, one "class" role, and two "instance" roles.

At the foundation of this access pattern, we need some `scope`s on the `Role` model:

```ruby
class Role < ApplicationRecord
  # ...
  scope :global, -> { where(resource_type: nil, resource_id: nil) }
  scope :for_class, ->(resource_class) { where(resource_type: resource_class, resource_id: nil) }
  scope :for_instance, ->(resource_instance) { where(resource: resource_instance) }
end
```

These scopes will allow us to quickly find roles of each type. But, we also will need to be able to quickly find roles of each name, so let's add some scopes that are custom to our application:

```ruby
class Role < ApplicationRecord
  # ...
  scope :developer, -> { where(name: :developer) }
  scope :manager, -> { where(name: :manager) }
  scope :member, -> { where(name: :member) }
end
```

Now, we can easily mix and match our type scopes and our name scopes to find precisely the roles we need. But, the `Role` model isn't really the natural origin from which we will be asking role-based questions; no, that would be the `User` model. So, what should our interface on the `User` model look like to clearly see what roles a user has? In my opinion, you shouldn't ask a `User` what roles it has and then make checks based on the content of that response; instead, you should ask a `User` if it has a particular role. So, let's add some methods to the `User` model to do just that:

```ruby
class User < ApplicationRecord
  # ...
  def developer? = roles.developer.global.exists?

  def admin? = roles.admin.global.exists?

  def campaign_manager? = roles.manager.for_class("Campaign").exists?

  def member_of?(resource) = roles.member.for_instance(resource).exists?

  def manager_of?(resource) = roles.manager.for_instance(resource).exists?
end
```

These methods exactly capture the landscope of our application's roles. I use these methods in my policy classes to drive authorization. And maybe I'll write more in-depth about that in the future, but there isn't much magical going on. What I want to dig into here at the close is how we can leverage this data model to bring wonderful clarity and expressiveness to our application.

- - -

Here was the feature I needed to add today:

> An `admin` needs to be able to manage a `Customer`'s `manager`s.

The UX that I wanted was to add a collection of checkboxes to the `Customer` edit form that would allow an `admin` to select which `User`s should be `manager`s of the `Customer`. One of the niceties of Rails is that it makes it easy to manage a `has_many` association via a collection of checkboxes:

```ruby
# /app/models/customer.rb
class Customer < ApplicationRecord
  # ...
  has_many :managers
end

# /app/controllers/customers_controller.rb
class CustomersController < ApplicationController
  # ...

  # PATCH/PUT /customers/1
  def update
    if @customer.update(customer_params)
      redirect_to @customer, notice: "Customer was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def customer_params
    params.require(:customer).permit(
      # ...
      manager_ids: []
    )
  end
end

# /app/views/customers/_form.html.erb
<%= form.collection_check_boxes(:manager_ids, User.all.pluck(:id, :username), :first, :last) %>
```

This is a pretty straightforward feature, but it is a great example of how we can leverage our role-based authorization to drive our application's behavior.




has_one :csm_role, ->(customer) { manager.for_instance(customer) }, class_name: "Role", inverse_of: :resource
has_many :manager_roles, through: :csm_role, source: :user_roles
has_many :managers, through: :manager_roles, source: :user

def managers
  User.where(id: UserRole.where(role: Role.manager.for_class("Customer")).select(:user_id))
end
