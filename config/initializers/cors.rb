# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # 許可オリジンを環境変数から取得（カンマ区切り）
    # 例: ALLOWED_ORIGINS="https://example.com,https://partner.com"
    origins ENV.fetch("ALLOWED_ORIGINS", "http://localhost:3001").split(",")

    resource "/api/*",
      headers: %w[Authorization Content-Type],
      methods: [ :get, :post, :options, :head ],
      credentials: true
  end
end
