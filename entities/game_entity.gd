extends Node
class_name GameEntity

## Base entity lifecycle (Lane 1 AC). NPCs, Workmon instances, and other
## spawnable game objects extend this instead of each lane inventing its
## own spawn/despawn bookkeeping.

signal spawned
signal despawned

var entity_id: String = ""
var is_active: bool = false

func spawn(id: String) -> void:
	entity_id = id
	is_active = true
	spawned.emit()

func despawn() -> void:
	is_active = false
	despawned.emit()
	queue_free()
