# Copyright 2023, David Goodwin. All rights reserved.
#
# This file is part of Hecate. Hecate is free software: you can
# redistribute it and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.
#
# Hecate is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License
# along with Hecate. If not, see <https://www.gnu.org/licenses/>.

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
