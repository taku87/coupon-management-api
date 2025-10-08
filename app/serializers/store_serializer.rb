# frozen_string_literal: true

class StoreSerializer
  include JSONAPI::Serializer

  set_type :store
  set_id :id

  attributes :name,
             :created_at,
             :updated_at
end
