shader_type spatial;
render_mode unshaded;

uniform bool use_screenspace = false;

void vertex() {
	// For testing, lock to camera: it should match the player's view perfectly
	//render_mode cull_disabled, depth_test_disabled, depth_draw_always;
	//POSITION = vec4(VERTEX.x * 2.0, VERTEX.y * (0.75 + 0.25 * sin(TIME)), 0.0, 1.0);
}

uniform sampler2D textureL;
uniform sampler2D textureR;
void fragment() {
	vec2 uv;
	if (use_screenspace) {
		uv = vec2(SCREEN_UV.x, SCREEN_UV.y);
	} else {
		uv = vec2(UV.x,  UV.y);
	}
	
	if(VIEW_INDEX==0)
		ALBEDO = texture(textureL,uv).rgb;
	else
		ALBEDO = texture(textureR,uv).rgb;
	ALBEDO *= vec3(0.3,0.5,1.0);
	
	// Place fragment code here.
}
