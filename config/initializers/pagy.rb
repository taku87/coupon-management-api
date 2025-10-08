# frozen_string_literal: true

require "pagy/extras/overflow"

# Pagy設定
Pagy::DEFAULT[:page] = 1           # デフォルトページ
Pagy::DEFAULT[:items] = 20         # 1ページあたりのアイテム数
Pagy::DEFAULT[:max_items] = 100    # 1ページあたりの最大アイテム数
Pagy::DEFAULT[:overflow] = :last_page # ページ範囲外の場合は最終ページを表示
