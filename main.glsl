precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

// Params
const int bounces = 3; // Dont go beyond 20
const int samples = 3;
const float base_reflection = 0.3;
float init_energy = 2.0;
float decay_multiplier = 0.5;
float roughness = 0.05;

vec3 EmptyVector = vec3(-69,1000000,-69); // EmptyVector
float MathInf = 1000000.0; // Math.inf

struct Ray{
    vec3 origin;
    vec3 direction;
    // invert function to be overloaded
};

struct Plane{
    vec3 position;
    vec3 normal;
    vec3 color;
};

struct Sphere{
    vec3 position;
    float radius;
    vec3 color;
};

struct PointLight{
    vec3 position;
    vec3 color;
    float intensity;
};

struct Camera{
    vec3 position;
    vec3 forward;
    vec3 right;
    vec3 down;
    float fov;

    float canvas_distance;
    vec3 canvas_origin;
};

struct HitParams{
    vec3 color;
    vec3 light;
    vec3 position;
    vec3 normal;
};

// Normal calculation function overloading
// Plane normal
vec3 calculate_normal(Plane plane, vec3 point){
    return plane.normal;
}

// Sphere normal
vec3 calculate_normal(Sphere sphere, vec3 point){
    return normalize(point - sphere.position);
}

// Collision calculation function overloading
// Plane collision
vec3 hit(Plane plane, Ray r){
    float d = dot(plane.position, -plane.normal);
    float denom = dot(r.direction, plane.normal);
    float t;

    if(denom == 0.0){
        t = -MathInf;
    }else{
        t = -(d + dot(r.origin, plane.normal)) / denom;
    }

    if(t < 0.0){
        return EmptyVector;
    }else{
        return r.origin + (r.direction * t);
    }
}

// Sphere collision
vec3 hit(Sphere sphere, Ray r){
    float a = dot(r.direction, r.direction);
    vec3 f = r.origin - sphere.position;
    float b = 2.0 * (dot(f, r.direction));
    float c = (dot(f, f)) - (dot(sphere.radius, sphere.radius));

    float discriminant = b * b - 4.0 * a * c;

    if(discriminant >= 0.0){
        float root = sqrt(discriminant);
        float t0 = (-b - root)/(2.0*a);
        float t1 = (-b + root)/(2.0*a);

        if(t0 >= 0.0){
            return r.origin + (r.direction * t0);
        }else if(t1 >= 0.0){
            return r.origin + (r.direction * t1);
        }
    }

    return EmptyVector;
}

// Noise functions
float PHI = 1.61803398874989484820459 * 00000.1; // Golden Ratio   
float PI  = 3.14159265358979323846264 * 00000.1; // PI
float SQ2 = 1.41421356237309504880169 * 10000.0; // Square Root of Two

float gold_noise(in vec2 coordinate, in float seed){
    return fract(tan(distance(coordinate*(seed+PHI), vec2(PHI, PI)))*SQ2);
}

float random (float x) {
    return fract(sin(x)*43758.5453123);
}
// Noise functions end

const int num_pointlights = 2;
const int num_spheres = 3;
const int num_planes = 6;

// Ambient Light Intensity
float ambient_intensity = 0.05;
vec3 ambient_color = vec3(1) * ambient_intensity;
float distance_lights = 0.2;

HitParams trace(Ray r, PointLight pointlights[num_pointlights],
Plane planes[num_planes], Sphere spheres[num_spheres]){
    // Initializing color with background color
    vec3 color = vec3(1);

    // Initializing closest_hit_point and min_dist with plane
    vec3 closest_hit_point = EmptyVector;
    vec3 obj_normal = EmptyVector;
    float min_dist = MathInf;

    // Check collision against all planes
    for(int i=0; i<num_planes; i++){
        vec3 hit_point = hit(planes[i], r);
        float dist = distance(hit_point, r.origin);

        if(dist < min_dist){
            min_dist = dist;
            closest_hit_point = hit_point;
            color = planes[i].color;
            obj_normal = calculate_normal(planes[i], closest_hit_point);
        }
    }
    
    // Check collision against all spheres
    for(int i=0; i<num_spheres; i++){
        vec3 hit_point = hit(spheres[i], r);
        float dist = distance(hit_point, r.origin);

        if(dist < min_dist){
            min_dist = dist;
            closest_hit_point = hit_point;
            color = spheres[i].color;
            obj_normal = calculate_normal(spheres[i], closest_hit_point);
        }
    }

    // Calculating shadow ray
    vec3 total_lightcolor = ambient_color;
    if(closest_hit_point != EmptyVector){
        for(int l=0; l<num_pointlights; l++){

            bool object_in_way = false;
            float intensity = 1.0;
            vec3 lightcolor = pointlights[l].color * pointlights[l].intensity;

            Ray shadow_ray;
            vec3 shadow_Ray_direction = normalize(pointlights[l].position - closest_hit_point);
            shadow_ray.origin = closest_hit_point + (obj_normal * 0.00001);
            shadow_ray.direction = shadow_Ray_direction;

            // Initializing min dist from light distance
            float min_dist = distance(shadow_ray.origin, pointlights[l].position);

            // Now we will check ray distance against all objects
            // Checking shadow ray against plane
            vec3 hit_point = EmptyVector;
            float dist = MathInf;

            // Checking shadow ray against planes
            for(int i=0; i<num_planes; i++){
                vec3 hit_point = hit(planes[i], shadow_ray);
                float dist = distance(shadow_ray.origin, hit_point);

                if(dist < min_dist){
                    lightcolor = ambient_color;
                    object_in_way = true;
                    break;
                }
            }

            if(!object_in_way){
                // Checking shadow ray against sphere
                for(int i=0; i<num_spheres; i++){
                    vec3 hit_point = hit(spheres[i], shadow_ray);
                    float dist = distance(shadow_ray.origin, hit_point);

                    if(dist < min_dist){
                        lightcolor = ambient_color;
                        object_in_way = true;
                        break;
                    }
                }
            }

            if(!object_in_way){
                // Shading
                float diff_angle = dot(shadow_ray.direction, obj_normal);
                if(diff_angle < 0.0){
                    diff_angle = 0.0;
                }
                
                lightcolor = lightcolor * diff_angle + ambient_color;

            }

            total_lightcolor += lightcolor;

        }

        if(total_lightcolor.x > 1.0){
            total_lightcolor.x = 1.0;
        }
        if(total_lightcolor.y > 1.0){
            total_lightcolor.y = 1.0;
        }
        if(total_lightcolor.z > 1.0){
            total_lightcolor.z = 1.0;
        }
        
    }

    HitParams cc;
    cc.color = color;
    cc.light = total_lightcolor;
    cc.position = closest_hit_point;
    cc.normal = obj_normal;
    return cc;

}

void main() {
    // Accessing the uv's of screen
    vec2 st = gl_FragCoord.xy / u_resolution.xy;
    st.x *= u_resolution.x / u_resolution.y; // maintaining aspect ratio

    // Lights definition and properties
    PointLight L;
    L.position = vec3(distance_lights * sin(u_time), 
    0.2, distance_lights * cos(u_time));
    L.color = vec3(0.7216, 0.7216, 1.0);
    L.intensity = 0.4;

    PointLight L2;
    L2.position = vec3(distance_lights * cos(u_time), 
    0.2, distance_lights * sin(u_time));
    L2.color = vec3(1.0, 0.6941, 0.6941);
    L2.intensity = 0.99;

    PointLight pointlights[num_pointlights];
    pointlights[0] = L;
    pointlights[1] = L2;

    // Spheres definition and properties
    Sphere S;
    S.position = vec3(0.15, 0.0, 0.0);
    S.radius = 0.1;
    S.color = vec3(0.1569, 0.5608, 0.1569);

    Sphere S2;
    S2.position = vec3(-0.15, 0.0, 0.0);
    S2.radius = 0.1;
    S2.color = vec3(0.1608, 0.1686, 0.5529);

    Sphere S3;
    S3.position = vec3(0.0, 0.0, -0.2);
    S3.radius = 0.1;
    S3.color = vec3(0.5333, 0.149, 0.149);

    Sphere spheres[num_spheres];
    spheres[0] = S;
    spheres[1] = S2;
    spheres[2] = S3;

    // Planes definition and properties
    Plane p; // Floor
    p.position = vec3(0.0,-0.1,0.0);
    p.normal = vec3(0.0,1.0,0.0);
    p.color = vec3(0.5255, 0.5255, 0.5255);

    Plane p2; // Left
    p2.position = vec3(0.3,0.0,0.0);
    p2.normal = vec3(-1.0,0.0,0.0);
    p2.color = vec3(0.5333, 0.1569, 0.1569);

    Plane p3; // Right
    p3.position = vec3(-0.3,0.0,0.0);
    p3.normal = vec3(1.0,0.0,0.0);
    p3.color = vec3(0.1725, 0.5294, 0.1608);

    Plane p4; // Back
    p4.position = vec3(0.0,0.0,-0.4);
    p4.normal = vec3(0.0,0.0,1.0);
    p4.color = vec3(0.1529, 0.2039, 0.5059);

    Plane p5; // Ceiling
    p5.position = vec3(0.0,0.3,0.0);
    p5.normal = vec3(0.0,-1.0,0.0);
    p5.color = vec3(0.5333, 0.5333, 0.5333);

    Plane p6; // Camera Back
    p6.position = vec3(0.0,0.0,0.8);
    p6.normal = vec3(0.0,0.0,-1.0);
    p6.color = vec3(0.5255, 0.5255, 0.5255);

    Plane planes[num_planes];
    planes[0] = p;
    planes[1] = p2;
    planes[2] = p3;
    planes[3] = p4;
    planes[4] = p5;
    planes[5] = p6;
    // Created objects

    // Camera definition and properties
    Camera cam;
    cam.position = vec3(0, 0.1, 0.7);
    vec3 lookAtPosition = vec3(sin(u_time)/10.0,cos(u_time)/10.0,cam.position.z * -2.0);
    cam.forward = normalize(lookAtPosition - cam.position);
    // cam.forward = vec3(0,0,1);
    cam.right = cross(cam.forward, p.normal);
    cam.down = cross(cam.forward, cam.right);
    cam.fov = 80.0;
    cam.canvas_distance = 0.5/tan(cam.fov/180.0);
    cam.canvas_origin = cam.position + cam.forward*cam.canvas_distance;

    // Tracing begins
    mediump float smp = float(samples);
    vec3 total_color;
    for(int s=0; s<samples; s++){
        // Ray initial cast
        // Creating ray
        Ray initial_ray;
        initial_ray.origin = cam.position;
        mediump float ss = float(s);
        vec3 canvas_position = cam.canvas_origin + (cam.right * (0.5 - st.x+((ss*st.x)/(smp*u_resolution.x)))) + (cam.down * (0.5 - st.y));
        initial_ray.direction = normalize(canvas_position - initial_ray.origin);
        // Created ray

        // Inital hit param to store collision information
        HitParams intial_hit;
        intial_hit = trace(initial_ray, pointlights, planes, spheres);

        // Reflection bounce
        vec3 mul_color = intial_hit.color; // color to multiply
        float energy = init_energy * decay_multiplier;
        vec3 total_bounce_color = mul_color * intial_hit.light * energy; // intializing intialially with diffuse color

        // intializing previous ray attributes
        vec3 prev_hit_point = intial_hit.position;
        vec3 prev_normal = intial_hit.normal;
        vec3 prev_ray_dir = initial_ray.direction;

        // bounces calculation begin
        for(int i=0; i<bounces; i++){
            Ray r;
            r.origin = prev_hit_point + prev_normal * 0.00001;
            r.direction = prev_ray_dir - (prev_normal * (dot(prev_ray_dir, prev_normal) * 2.0));
            r.direction += roughness * normalize(vec3(
                0.5-gold_noise(st,r.direction.x*10000.0),
                0.5-gold_noise(st,r.direction.y*10000.0),
                0.5-gold_noise(st,r.direction.z*10000.0)));
            r.direction = normalize(r.direction);

            HitParams hit;
            hit = trace(r, pointlights, planes, spheres);

            energy *= decay_multiplier;
            mul_color *= hit.color; // for glass reflections do mul_color = hit.color
            mul_color = normalize(mul_color); // normalizing color becuase it will be neutralized by light later
            total_bounce_color += mul_color * hit.light * energy;

            prev_hit_point = hit.position;
            prev_normal = hit.normal;
            prev_ray_dir = r.direction;
        }

        float fresnel_dot = dot(-initial_ray.direction, intial_hit.normal) - base_reflection;
        if(fresnel_dot < 0.0){ fresnel_dot = 0.0; }
        total_bounce_color = (intial_hit.color * fresnel_dot) + (total_bounce_color * (1.0 - fresnel_dot));

        total_color += total_bounce_color/smp;
    }

    // Clipping total color
    if(total_color.x > 1.0){ total_color.x = 1.0; }
    if(total_color.y > 1.0){ total_color.y = 1.0; }
    if(total_color.z > 1.0){ total_color.z = 1.0; }

    gl_FragColor = vec4(total_color, 1);

}