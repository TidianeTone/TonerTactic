shader_type spatial;
// Pierre, végétation et unités voxel : couleur et occlusion viennent des sommets (cuits dans Blender).

uniform float sway = 0.0;         // balancement du feuillage
uniform float backlight = 0.0;    // transluscence des feuilles à contre-jour
uniform float water_y = 0.34;
uniform float cut = 1.0;          // découpe du décor côté caméra
global uniform vec2 cut_dir;      // direction caméra au sol, depuis le centre de l'arène
global uniform vec2 cut_center;
global uniform float cut_half;
uniform float moss = 0.0;         // mousse sur les faces tournées vers le ciel
uniform vec4 units[16];          // xyz : torse des unités, w : 1 si active
uniform int unit_n = 0;
instance uniform float flash = 0.0;
instance uniform vec3 rim = vec3(0.0);
uniform bool use_tex = false;    // modèles HD allégés (tools/hd_web.py) : la couleur vient d'une texture, pas des sommets
uniform sampler2D albedo_tex : source_color, filter_nearest;

varying vec3 wpos;

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	if (sway > 0.0) {
		float k = sway * abs(VERTEX.y);
		VERTEX.x += sin(TIME * 1.3 + wp.x * 0.7 + wp.z * 0.4) * 0.02 * k;
		VERTEX.z += cos(TIME * 1.1 + wp.z * 0.6 + wp.x * 0.3) * 0.02 * k;
	}
	wpos = wp;
}

float bayer(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	float m[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return (m[x + y * 4] + 0.5) / 16.0;
}

void fragment() {
	// colonne entière et ombre comprise : un mur découpé ne laisse ni socle ni ombre orpheline
	if (cut > 0.0) {
		vec2 rel = wpos.xz - cut_center;
		float outside = max(abs(rel.x), abs(rel.y));
		float along = dot(rel, cut_dir);
		float fade = smoothstep(cut_half + 0.6, cut_half + 1.1, outside) * smoothstep(2.5, 3.5, along);
		if (fade > 0.5) {
			discard;
		}
	}
	// ce qui cache une unité s'efface en trame : on voit à travers sans perdre la forme
	if (unit_n > 0 && PROJECTION_MATRIX[3][3] < 0.5) {
		vec3 cam = INV_VIEW_MATRIX[3].xyz;
		bool hide = false;
		for (int i = 0; i < 16; i++) {
			if (i >= unit_n) {
				break;
			}
			vec3 seg = units[i].xyz - cam;
			float L = length(seg);
			vec3 dir = seg / L;
			float t = dot(wpos - cam, dir);
			// assez loin devant l'unité, au-dessus de ses pieds, dans un tube serré autour du rayon
			if (t > 0.5 && t < L - 1.0 && wpos.y > units[i].y - 0.5 && length(wpos - (cam + dir * t)) < 0.5) {
				hide = true;
			}
		}
		if (hide && bayer(FRAGCOORD.xy) < 0.62) {
			discard;
		}
	}
	vec3 c = use_tex ? texture(albedo_tex, UV).rgb : COLOR.rgb;
	float wet = 1.0 - smoothstep(water_y - 0.05, water_y + 0.22, wpos.y);
	c = mix(c, c * vec3(0.5, 0.62, 0.58), wet * 0.85);
	if (moss > 0.0) {
		vec3 wn = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
		vec2 q = floor(wpos.xz * 16.0 + wpos.y * 7.0);
		float nz = fract(sin(dot(floor(wpos.xz * 2.2), vec2(12.9898, 78.233))) * 43758.5453);
		float speck = fract(sin(dot(q, vec2(39.3468, 11.135))) * 24634.6345);
		float m = step(0.8, wn.y) * step(0.72, nz) * step(0.45, speck) * moss;
		c = mix(c, vec3(0.2, 0.3, 0.1) * (0.8 + speck * 0.4), m * 0.75);
		// patine : les pieds de mur foncent
		c *= mix(0.78, 1.0, smoothstep(0.3, 2.2, wpos.y));
	}
	// coup : blanc à l'impact, puis braise qui s'éteint
	vec3 hit = mix(vec3(1.0, 0.42, 0.18), vec3(1.0), smoothstep(0.3, 0.55, flash));
	ALBEDO = mix(c, hit, flash * 0.6);
	ROUGHNESS = mix(0.9, 0.3, wet);
	SPECULAR = 0.35;
	BACKLIGHT = c * backlight;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
	EMISSION = vec3(1.0, 0.45, 0.15) * flash * (0.4 + fres * 2.0) + rim * fres;
}
