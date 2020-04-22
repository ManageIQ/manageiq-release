require 'config'

Config.load_and_set_settings(ManageIQ::Release::CONFIG_DIR.join("settings.yml").to_s, ManageIQ::Release::CONFIG_DIR.join("settings.local.yml").to_s)
