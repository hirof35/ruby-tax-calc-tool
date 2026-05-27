require 'tk'
require 'tkextlib/tile'

# メインウィンドウの設定
root = TkRoot.new do
  title "税務・書類計算マルチツール"
  geometry "550x450"
end

# ウィンドウサイズが子要素に引っ張られて勝手に変わるのを防ぐ
root.pack_propagate(false)

# タブを管理するノートブックの作成
notebook = Tk::Tile::Notebook.new(root) do
  pack('fill' => 'both', 'expand' => true, 'padx' => 10, 'pady' => 10)
end

# 3桁区切りの共通メソッド（コードをスッキリさせるため分離）
def format_currency(number)
  number.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\1,')
end

# ツール1: 報酬の源泉徴収計算
tab1 = TkFrame.new(notebook)
notebook.add(tab1, 'text' => '源泉徴収・手取り計算')

# 入力欄
TkLabel.new(tab1, 'text' => '額面報酬額 (税抜/円):').grid('row' => 0, 'column' => 0, 'padx' => 15, 'pady' => 15, 'sticky' => 'w')
amount_entry = TkEntry.new(tab1).grid('row' => 0, 'column' => 1, 'padx' => 15, 'pady' => 15)

# 消費税チェックボックス
tax_check_var = TkVariable.new(0)
TkCheckButton.new(tab1, 'text' => '消費税(10%)を別途支給する', 'variable' => tax_check_var).grid('row' => 1, 'column' => 0, 'columnspan' => 2, 'padx' => 15, 'pady' => 5, 'sticky' => 'w')

# 結果表示用のラベル群
res_tax_label   = TkLabel.new(tab1, 'text' => '消費税額: 0 円').grid('row' => 3, 'column' => 0, 'columnspan' => 2, 'sticky' => 'w', 'padx' => 25, 'pady' => 2)
res_wht_label   = TkLabel.new(tab1, 'text' => '源泉徴収税額: 0 円').grid('row' => 4, 'column' => 0, 'columnspan' => 2, 'sticky' => 'w', 'padx' => 25, 'pady' => 2)
res_total_label = TkLabel.new(tab1, 'text' => '差引手取り受取額: 0 円', 'font' => 'Helvetica 12 bold', 'fg' => 'blue').grid('row' => 5, 'column' => 0, 'columnspan' => 2, 'pady' => 15, 'sticky' => 'w', 'padx' => 25)

# 計算ロジック
calc_withholding = proc {
  gamen = amount_entry.value.to_i
  
  # 消費税計算
  shouhizei = tax_check_var.value == "1" ? (gamen * 0.10).floor : 0
  
  # 源泉徴収税額の計算 (100万円超の2段階スライド)
  if gamen <= 1_000_000
    wht = (gamen * 0.1021).floor
  else
    wht = ((1_000_000 * 0.1021) + ((gamen - 1_000_000) * 0.2042)).floor
  end
  
  tedori = gamen + shouhizei - wht
  
  # 画面更新
  res_tax_label.text   = "消費税額 (10%): #{format_currency(shouhizei)} 円"
  res_wht_label.text   = "源泉徴収税額: #{format_currency(wht)} 円"
  res_total_label.text = "差引手取り受取額: #{format_currency(tedori)} 円"
}

TkButton.new(tab1, 'text' => '税額を計算する', 'command' => calc_withholding).grid('row' => 2, 'column' => 0, 'columnspan' => 2, 'pady' => 15)

# ツール2: 請求書用 消費税内訳計算

tab2 = TkFrame.new(notebook)
notebook.add(tab2, 'text' => '消費税・内外税一発計算')

TkLabel.new(tab2, 'text' => '対象金額 (円):').grid('row' => 0, 'column' => 0, 'padx' => 15, 'pady' => 15, 'sticky' => 'w')
invoice_amt_entry = TkEntry.new(tab2).grid('row' => 0, 'column' => 1, 'padx' => 15, 'pady' => 15)

# 内外税ラジオボタン
tax_type = TkVariable.new('outer')
TkRadioButton.new(tab2, 'text' => '外税（税別入力）', 'variable' => tax_type, 'value' => 'outer').grid('row' => 1, 'column' => 0, 'padx' => 15, 'pady' => 5, 'sticky' => 'w')
TkRadioButton.new(tab2, 'text' => '内税（税込入力）', 'variable' => tax_type, 'value' => 'inner').grid('row' => 1, 'column' => 1, 'padx' => 15, 'pady' => 5, 'sticky' => 'w')

# 税率選択スライダー（値を丸める処理をロジックに追加）
rate_var = TkVariable.new(10)
TkLabel.new(tab2, 'text' => '適用税率 (%):').grid('row' => 2, 'column' => 0, 'padx' => 15, 'pady' => 5, 'sticky' => 'w')
TkScale.new(tab2, 'from' => 8, 'to' => 10, 'variable' => rate_var, 'orient' => 'horizontal').grid('row' => 2, 'column' => 1, 'padx' => 15, 'pady' => 5)

# 結果表示
inv_res_hontai = TkLabel.new(tab2, 'text' => '税抜本体価格: 0 円').grid('row' => 4, 'column' => 0, 'columnspan' => 2, 'sticky' => 'w', 'padx' => 25, 'pady' => 2)
inv_res_zei    = TkLabel.new(tab2, 'text' => '消費税額: 0 円').grid('row' => 5, 'column' => 0, 'columnspan' => 2, 'sticky' => 'w', 'padx' => 25, 'pady' => 2)
inv_res_total  = TkLabel.new(tab2, 'text' => '税込合計金額: 0 円', 'font' => 'Helvetica 12 bold', 'fg' => 'darkgreen').grid('row' => 6, 'column' => 0, 'columnspan' => 2, 'sticky' => 'w', 'padx' => 25, 'pady' => 15)

# 消費税計算ロジック
calc_invoice_tax = proc {
  input_val = invoice_amt_entry.value.to_i
  # スライダーが小数点を返しても8か10に綺麗に丸める
  display_rate = rate_var.value.to_f.round
  rate = display_rate / 100.0
  
  if tax_type.value == 'outer'
    hontai = input_val
    zei = (hontai * rate).floor
    zeikomi = hontai + zei
  else
    zeikomi = input_val
    hontai = (zeikomi / (1.0 + rate)).ceil
    zei = zeikomi - hontai
  end

  inv_res_hontai.text = "税抜本体価格: #{format_currency(hontai)} 円"
  inv_res_zei.text    = "消費税額 (#{display_rate}%): #{format_currency(zei)} 円"
  inv_res_total.text  = "税込合計金額: #{format_currency(zeikomi)} 円"
}

TkButton.new(tab2, 'text' => '消費税を計算する', 'command' => calc_invoice_tax).grid('row' => 3, 'column' => 0, 'columnspan' => 2, 'pady' => 15)

Tk.mainloop
