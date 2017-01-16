Settings = class(function(acc)
end)
function Settings:Init()

	self.db_path = getScriptPath() .. "\\positions2.db"
	
	self.dark_theme = true
	
	self.show_total_collateral_on_forts = true		--last rows show totals of collateral on FORTS by client_code
end