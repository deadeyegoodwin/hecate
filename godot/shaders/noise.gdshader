// Copyright 2023, David Goodwin. All rights reserved.
//
// This file is part of Hecate. Hecate is free software: you can
// redistribute it and/or modify it under the terms of the GNU General
// Public License as published by the Free Software Foundation, either
// version 3 of the License, or (at your option) any later version.
//
// Hecate is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
// for more details.
//
// You should have received a copy of the GNU General Public License
// along with Hecate. If not, see <https://www.gnu.org/licenses/>.

// Spatial shader that generates from a noise texture.

shader_type spatial;

// The magnitude of drift of the entire surface, in meters.
uniform float drift_size : hint_range(0.0, 1.0, 0.001) = 0.0;

// The amount of motion in the noise.
uniform float noise_motion : hint_range(0.0, 1.0, 0.01) = 0.5;

// The rate that the alpha occalates for the primary and secondary colors.
uniform float primary_alpha_rate : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float secondary_alpha_rate : hint_range(0.0, 1.0, 0.01) = 0.0;

uniform vec4 primary_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 secondary_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform sampler2D noise;

void vertex() {
	VERTEX.xy += drift_size * sin(UV + TIME);
}

void fragment() {
	// From the noise texture, use the greyscale value to select color and alpha.
	float greyscale = texture(noise, UV + (TIME * noise_motion)).x;
	if (greyscale < 0.5) {
		ALBEDO = primary_color.rgb;
		ALPHA = primary_color.a * fract((greyscale * 2.0) + (TIME * primary_alpha_rate));
	} else {
		ALBEDO = secondary_color.rgb;
		ALPHA = secondary_color.a * fract(((greyscale - 0.5) * 2.0) + (TIME * secondary_alpha_rate));
	}

	RIM = 0.2;
	METALLIC = 0.0;
	ROUGHNESS = 0.75;
}
