# frozen_string_literal: true

# Storeリソースのシリアライザ（JSON:API準拠）
class StoreSerializer
  include JSONAPI::Serializer

  set_type :store
  set_id :id

  attributes :name,
             :created_at,
             :updated_at
end
