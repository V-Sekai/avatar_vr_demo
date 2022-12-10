shader_type spatial;
render_mode unshaded;

uniform sampler2D textureL;
uniform sampler2D textureR;
void fragment() {
	vec2 uv = vec2(1.0-UV.x,  UV.y);
	
	if(VIEW_INDEX==0)
		ALBEDO = texture(textureL,uv).rgb;
	else
		ALBEDO = texture(textureR,uv).rgb;
	
	// Place fragment code here.
}
