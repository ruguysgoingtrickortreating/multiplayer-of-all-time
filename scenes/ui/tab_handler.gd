extends TabContainer

func _on_tab_clicked(tab):
	if current_tab == tab:
		$Chat.visible = not $Chat.visible
