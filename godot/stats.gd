# Copyright (c) 2023, David Goodwin. All rights reserved.

# Manage a general set of statistics.
class_name HecateStatistics extends RefCounted

# Enumeration for common statistics.
enum Kind { HEALTH }

# Dictionary of statistics
var _stats := {}

# Create the statistics from a dictionary.
func _init(d : Dictionary) -> void:
	_stats = d.duplicate()

# Set statistic 'k' to value 'v'.
func set_stat(k, v) -> void:
	_stats[k] = v

# Return the value for statistic 'k', or null if no such statistic.
func get_stat(k):
	return _stats.get(k, null)
