class UpdateObjectManager2 < ActiveRecord::Migration
  def up

    #remove_index :object_manager_attributes, [:name]

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'login',
      display: 'Login',
      data_type: 'input',
      data_option: {
        type: 'text',
        maxlength: 100,
        null: true,
        autocapitalize: false,
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
        edit: {},
        view: {
          '-all-' => {
            shown: false,
          },
        },
      },
      pending_migration: false,
      position: 100,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'firstname',
      display: 'Firstname',
      data_type: 'input',
      data_option: {
        type: 'text',
        maxlength: 150,
        null: false,
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        signup: {
          '-all-' => {
            null: false,
          },
        },
        invite_agent: {
          '-all-' => {
            null: false,
          },
        },
        edit: {
          '-all-' => {
            null: false,
          },
        },
        view: {
          '-all-' => {
            shown: true,
          },
        },
      },
      pending_migration: false,
      position: 200,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'lastname',
      display: 'Lastname',
      data_type: 'input',
      data_option: {
        type: 'text',
        maxlength: 150,
        null: false,
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        signup: {
          '-all-' => {
            null: false,
          },
        },
        invite_agent: {
          '-all-' => {
            null: false,
          },
        },
        edit: {
          '-all-' => {
            null: false,
          },
        },
        view: {
          '-all-' => {
            shown: true,
          },
        },
      },
      pending_migration: false,
      position: 300,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'email',
      display: 'Email',
      data_type: 'input',
      data_option: {
        type: 'email',
        maxlength: 150,
        null: false,
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        signup: {
          '-all-' => {
            null: false,
          },
        },
        invite_agent: {
          '-all-' => {
            null: false,
          },
        },
        edit: {
          '-all-' => {
            null: false,
          },
        },
        view: {
          '-all-' => {
            shown: true,
          },
        },
      },
      pending_migration: false,
      position: 400,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'web',
      display: 'Web',
      data_type: 'input',
      data_option: {
        type: 'url',
        maxlength: 250,
        null: true,
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
        edit: {
          '-all-' => {
            null: true,
          },
        },
        view: {
          '-all-' => {
            shown: true,
          },
        },
      },
      pending_migration: false,
      position: 500,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'phone',
      display: 'Phone',
      data_type: 'input',
      data_option: {
        type: 'phone',
        maxlength: 100,
        null: true,
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
        edit: {
          '-all-' => {
            null: true,
          },
        },
        view: {
          '-all-' => {
            shown: true,
          },
        },
      },
      pending_migration: false,
      position: 600,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'mobile',
      display: 'Mobile',
      data_type: 'input',
      data_option: {
        type: 'phone',
        maxlength: 100,
        null: true,
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
        edit: {
          '-all-' => {
            null: true,
          },
        },
        view: {
          '-all-' => {
            shown: true,
          },
        },
      },
      pending_migration: false,
      position: 700,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'fax',
      display: 'Fax',
      data_type: 'input',
      data_option: {
        type: 'phone',
        maxlength: 100,
        null: true,
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
        edit: {
          '-all-' => {
            null: true,
          },
        },
        view: {
          '-all-' => {
            shown: true,
          },
        },
      },
      pending_migration: false,
      position: 800,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'organization_id',
      display: 'Organization',
      data_type: 'autocompletion_ajax',
      data_option: {
        multiple: false,
        nulloption: true,
        null: true,
        relation: 'Organization',
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
        edit: {
          '-all-' => {
            null: true,
          },
        },
        view: {
          '-all-' => {
            shown: true,
          },
        },
      },
      pending_migration: false,
      position: 900,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'department',
      display: 'Department',
      data_type: 'input',
      data_option: {
        type: 'text',
        maxlength: 200,
        null: true,
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
        edit: {
          '-all-' => {
            null: true,
          },
        },
        view: {
          '-all-' => {
            shown: true,
          },
        },
      },
      pending_migration: false,
      position: 1000,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'street',
      display: 'Street',
      data_type: 'input',
      data_option: {
        type: 'text',
        maxlength: 100,
        null: true,
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
        edit: {
          '-all-' => {
            null: true,
          },
        },
        view: {
          '-all-' => {
            shown: true,
          },
        },
      },
      pending_migration: false,
      position: 1100,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'zip',
      display: 'Zip',
      data_type: 'input',
      data_option: {
        type: 'text',
        maxlength: 100,
        null: true,
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
        edit: {
          '-all-' => {
            null: true,
          },
        },
        view: {
          '-all-' => {
            shown: true,
          },
        },
      },
      pending_migration: false,
      position: 1200,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'city',
      display: 'City',
      data_type: 'input',
      data_option: {
        type: 'text',
        maxlength: 100,
        null: true,
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
        edit: {
          '-all-' => {
            null: true,
          },
        },
        view: {
          '-all-' => {
            shown: true,
          },
        },
      },
      pending_migration: false,
      position: 1300,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'password',
      display: 'Password',
      data_type: 'input',
      data_option: {
        type: 'password',
        maxlength: 100,
        null: true,
        autocomplete: 'off',
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        signup: {
          '-all-' => {
            null: false,
          },
        },
        invite_agent: {},
        edit: {
          Admin: {
            null: true,
          },
        },
        view: {}
      },
      pending_migration: false,
      position: 1400,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'vip',
      display: 'VIP',
      data_type: 'boolean',
      data_option: {
        null: true,
        default: false,
        item_class: 'formGroup--halfSize',
        options: {
          false: 'no',
          true: 'yes',
        },
        translate: true,
      },
      editable: false,
      active: true,
      screens: {
        edit: {
          Admin: {
            null: true,
          },
          Agent: {
            null: true,
          },
        },
        view: {
          '-all-' => {
            shown: false,
          },
        },
      },
      pending_migration: false,
      position: 1490,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'note',
      display: 'Note',
      data_type: 'richtext',
      data_option: {
        type: 'text',
        maxlength: 250,
        null: true,
        note: 'Notes are visible to agents only, never to customers.',
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
        edit: {
          '-all-' => {
            null: true,
          },
        },
        view: {
          '-all-' => {
            shown: true,
          },
        },
      },
      pending_migration: false,
      position: 1500,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'role_ids',
      display: 'Roles',
      data_type: 'checkbox',
      data_option: {
        multiple: true,
        null: false,
        relation: 'Role',
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
        edit: {
          Admin: {
            null: false,
          },
        },
        view: {
          '-all-' => {
            shown: false,
          },
        },
      },
      pending_migration: false,
      position: 1600,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'group_ids',
      display: 'Groups',
      data_type: 'checkbox',
      data_option: {
        multiple: true,
        null: true,
        relation: 'Group',
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {
          '-all-' => {
            null: false,
          },
        },
        edit: {
          Admin: {
            null: true,
          },
        },
        view: {
          '-all-' => {
            shown: false,
          },
        },
      },
      pending_migration: false,
      position: 1700,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'active',
      display: 'Active',
      data_type: 'active',
      data_option: {
        default: true,
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
        edit: {
          Admin: {
            null: false,
          },
        },
        view: {
          '-all-' => {
            shown: false,
          },
        },
      },
      pending_migration: false,
      position: 1800,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'Organization',
      name: 'name',
      display: 'Name',
      data_type: 'input',
      data_option: {
        type: 'text',
        maxlength: 150,
        null: false,
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        edit: {
          '-all-' => {
            null: false,
          },
        },
        view: {
          '-all-' => {
            shown: true,
          },
        },
      },
      pending_migration: false,
      position: 200,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'Organization',
      name: 'shared',
      display: 'Shared organization',
      data_type: 'boolean',
      data_option: {
        maxlength: 250,
        null: true,
        default: true,
        note: 'Customers in the organization can view each other items.',
        item_class: 'formGroup--halfSize',
        options: {
          true: 'Yes',
          false: 'No',
        }
      },
      editable: false,
      active: true,
      screens: {
        edit: {
          Admin: {
            null: false,
          },
        },
        view: {
          '-all-' => {
            shown: true,
          },
        },
      },
      pending_migration: false,
      position: 1400,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'Organization',
      name: 'note',
      display: 'Note',
      data_type: 'richtext',
      data_option: {
        type: 'text',
        maxlength: 250,
        null: true,
        note: 'Notes are visible to agents only, never to customers.',
      },
      editable: false,
      active: true,
      screens: {
        edit: {
          '-all-' => {
            null: true,
          },
        },
        view: {
          '-all-' => {
            shown: true,
          },
        },
      },
      pending_migration: false,
      position: 1500,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'Organization',
      name: 'active',
      display: 'Active',
      data_type: 'active',
      data_option: {
        default: true,
      },
      editable: false,
      active: true,
      screens: {
        edit: {
          Admin: {
            null: false,
          },
        },
        view: {
          '-all-' => {
            shown: false,
          },
        },
      },
      pending_migration: false,
      position: 1800,
      created_by_id: 1,
      updated_by_id: 1,
    )

  end

  def down
  end
end
