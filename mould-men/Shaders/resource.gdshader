shader_type spatial;

// The standard resource colour
uniform sampler2D tex : source_color;

// The colour of the resource and whether or not to modify
uniform vec4 true_col : source_color;
uniform bool modify_col = false;

// Hovering colour
uniform vec4 hover_col = vec4(0.1176, 0.5647, 1.0, 1.0);

// Boolean for whether or not the unit is being hovered
uniform bool is_hovered = false;

// Boolean for whether or not the unit is being hovered selected
uniform bool is_selected = false;

// Health value that will affect colouring
uniform float health_percent;

// Resource amount value that will affect colouring
uniform float res_percent;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {

	// Starter for the final colour
	vec4 final_col = texture(tex, UV);

	// Modify the colour if indicated
	if (modify_col) {
		final_col = mix(final_col, true_col, 0.95);;
	}

	// If the unit is being hovered then apply the hover colour
	if (is_hovered) {
		final_col = final_col * hover_col;

	// Show the normal colour
	} else {
		if (health_percent > 0.0 && !modify_col) {
			final_col = mix(final_col, vec4(1.0, 0.0, 0.0,  1.0), health_percent);
		} else {
			final_col = mix(final_col, vec4(0.5, 0.5, 0.5,  1.0), res_percent);
		}
	}

    ALBEDO = final_col.rgb;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
