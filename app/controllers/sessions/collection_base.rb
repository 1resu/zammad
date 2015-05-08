# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

module ExtraCollection
  def session( collections, assets, user )

    # all base stuff
    collections[ Locale.to_app_model ] = Locale.where( active: true )

    collections[ Taskbar.to_app_model ] = Taskbar.where( user_id: user.id )
    collections[ Taskbar.to_app_model ].each {|item|
      assets = item.assets(assets)
    }

    collections[ OnlineNotification.to_app_model ] = OnlineNotification.list(user, 30)
    assets = ApplicationModel.assets_of_object_list(collections[ OnlineNotification.to_app_model ], assets)

    collections[ RecentView.to_app_model ] = RecentView.list(user, 10)
    assets = RecentView.assets_of_object_list(collections[ RecentView.to_app_model ], assets)

    collections[ Role.to_app_model ] = []
    Role.all.each {|item|
      assets = item.assets(assets)
    }

    collections[ Group.to_app_model ] = []
    Group.all.each {|item|
      assets = item.assets(assets)
    }
    if !user.role?(Z_ROLENAME_CUSTOMER)
      collections[ Organization.to_app_model ] = []
      Organization.all.each {|item|
        assets = item.assets(assets)
      }
    else
      if user.organization_id
        collections[ Organization.to_app_model ] = []
        Organization.where( id: user.organization_id ).each {|item|
          assets = item.assets(assets)
        }
      end
    end
    [collections, assets]
  end
  module_function :session
end
