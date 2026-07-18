extends Node
## Loads translations.csv at runtime and applies the saved locale.
## Autoloaded after SaveManager. Call set_language() to switch locale live.

const CSV_PATH: String = "res://assets/translations/translations.csv"
const DEFAULT_LOCALE: String = "es"
const SUPPORTED_LOCALES: Array = ["es", "en", "pt_BR", "fr"]

func _ready() -> void:
	_load_csv()
	var lang: String = SaveManager.get_language()
	if lang.is_empty() or not lang in SUPPORTED_LOCALES:
		lang = DEFAULT_LOCALE
	TranslationServer.set_locale(lang)

func set_language(lang: String) -> void:
	if not lang in SUPPORTED_LOCALES:
		return
	SaveManager.set_language(lang)
	TranslationServer.set_locale(lang)

func get_current_language() -> String:
	return TranslationServer.get_locale()

func _load_csv() -> void:
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	if file == null:
		push_error("LocalizationManager: cannot open %s" % CSV_PATH)
		return
	var header: PackedStringArray = file.get_csv_line()
	if header.size() < 2:
		return
	var locale_count: int = header.size() - 1
	var translations: Array = []
	for i: int in locale_count:
		var t := Translation.new()
		t.locale = header[i + 1]
		translations.append(t)
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() < 2 or row[0].is_empty():
			continue
		var key: StringName = StringName(row[0])
		for i: int in mini(locale_count, row.size() - 1):
			var val: String = row[i + 1].replace("[BR]", "\n")
			(translations[i] as Translation).add_message(key, val)
	for t in translations:
		TranslationServer.add_translation(t as Translation)
