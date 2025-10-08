# frozen_string_literal: true

require "pagy/extras/overflow"
require "pagy/extras/limit"

# Pagy設定
Pagy::DEFAULT[:limit] = 20         # 1ページあたりのアイテム数（デフォルト）
Pagy::DEFAULT[:limit_max] = 100    # 1ページあたりの最大アイテム数
Pagy::DEFAULT[:limit_param] = :limit # URLパラメータ名
Pagy::DEFAULT[:overflow] = :last_page # ページ範囲外の場合は最終ページを表示
