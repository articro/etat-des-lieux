## DocumentLibrary — documents lisibles. Propriétaire : Systèmes. STUB M0 (tâche S-4).
extends Node

const DOCS_DIR := "res://data/documents/"

var _docs: Dictionary = {}    # StringName -> DocumentData
var _found: Dictionary = {}   # StringName -> true
var _read: Dictionary = {}    # StringName -> true


func _ready() -> void:
	var dir := DirAccess.open(DOCS_DIR)
	if dir == null:
		push_warning("DocumentLibrary : dossier %s introuvable (normal en M0)." % DOCS_DIR)
		return
	for file in dir.get_files():
		if file.ends_with(".tres") or file.ends_with(".res"):
			var res := load(DOCS_DIR + file)
			if res is DocumentData:
				_docs[(res as DocumentData).id] = res


func get_document(doc_id: StringName) -> DocumentData:
	return _docs.get(doc_id)


func mark_found(doc_id: StringName) -> void:
	if _found.has(doc_id):
		return
	_found[doc_id] = true
	var doc := get_document(doc_id)
	if doc != null:
		_apply_document_data(doc)
	EventBus.document_found.emit(doc_id)


## Applique les données du document : flags et objets révélés (demande Narration, 2026-10-17).
func _apply_document_data(doc: DocumentData) -> void:
	for flag: StringName in doc.sets_flags:
		GameState.set_flag(flag)
	for item_id: StringName in doc.reveals_items:
		InventoryManager.reveal_item(item_id)


func mark_read(doc_id: StringName) -> void:
	mark_found(doc_id)
	if _read.has(doc_id):
		return
	_read[doc_id] = true
	EventBus.document_read.emit(doc_id)


func is_read(doc_id: StringName) -> bool:
	return _read.has(doc_id)


func found_documents() -> Array[DocumentData]:
	var out: Array[DocumentData] = []
	for id: StringName in _found.keys():
		var d := get_document(id)
		if d != null:
			out.append(d)
	return out


func to_save_dict() -> Dictionary:
	return {
		"found": _found.keys().map(func(k: StringName) -> String: return String(k)),
		"read": _read.keys().map(func(k: StringName) -> String: return String(k)),
	}


func from_save_dict(d: Dictionary) -> void:
	_found.clear()
	_read.clear()
	for k: String in d.get("found", []):
		_found[StringName(k)] = true
	for k: String in d.get("read", []):
		_read[StringName(k)] = true
