# Manage statistics
class_name HecateStatistics extends Node

# Enumeration for common statistics.
enum Kind { HEALTH }

# Dictionary of statistics
var stats := {}

# Create the statistics from a dictionary.
func _init(d : Dictionary) -> void:
	stats = d.duplicate()

# Set statistic 'k' to value 'v'.
func set_stat(k, v) -> void:
	stats[k] = v

# Return the value for statistic 'k', or null if no such statistic.
func get_stat(k):
	return stats.get(k, null)
