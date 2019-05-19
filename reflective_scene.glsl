precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

/*
Object.types
0 -> Plane
1 -> Sphere
*/

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
    vec2 st = gl_FragCoord.xy / u_resolution.xy;
    st.x *= u_resolution.x / u_resolution.y;

    // Creating Point
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

    // Creating spheres
    Sphere S;
    S.position = vec3(0.15, 0.0, 0.0);
    S.radius = 0.1;
    S.color = vec3(0.102, 0.5451, 0.102);

    Sphere S2;
    S2.position = vec3(-0.15, 0.0, 0.0);
    S2.radius = 0.1;
    S2.color = vec3(0.1176, 0.1176, 0.5412);

    Sphere S3;
    S3.position = vec3(0.0, 0.0, -0.2);
    S3.radius = 0.1;
    S3.color = vec3(0.5529, 0.1294, 0.1294);

    Sphere spheres[num_spheres];
    spheres[0] = S;
    spheres[1] = S2;
    spheres[2] = S3;

    // Creating plane
    Plane p; // Floor
    p.position = vec3(0.0,-0.1,0.0);
    p.normal = vec3(0.0,1.0,0.0);
    p.color = vec3(0.5137, 0.5137, 0.5137);

    Plane p2; // Left
    p2.position = vec3(0.3,0.0,0.0);
    p2.normal = vec3(-1.0,0.0,0.0);
    p2.color = vec3(0.5608, 0.1255, 0.1255);

    Plane p3; // Right
    p3.position = vec3(-0.3,0.0,0.0);
    p3.normal = vec3(1.0,0.0,0.0);
    p3.color = vec3(0.1333, 0.5333, 0.1216);

    Plane p4; // Back
    p4.position = vec3(0.0,0.0,-0.4);
    p4.normal = vec3(0.0,0.0,1.0);
    p4.color = vec3(0.1216, 0.1216, 0.5608);

    Plane p5; // Ceiling
    p5.position = vec3(0.0,0.3,0.0);
    p5.normal = vec3(0.0,-1.0,0.0);
    p5.color = vec3(0.5333, 0.5333, 0.5333);

    Plane p6; // Camera Back
    p6.position = vec3(0.0,0.0,0.8);
    p6.normal = vec3(0.0,0.0,-1.0);
    p6.color = vec3(0.5608, 0.1216, 0.4275);

    Plane planes[num_planes];
    planes[0] = p;
    planes[1] = p2;
    planes[2] = p3;
    planes[3] = p4;
    planes[4] = p5;
    planes[5] = p6;
    // Created objects

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

    vec3 canvas_position = cam.canvas_origin + (cam.right * (0.5 - st.x)) + (cam.down * (0.5 - st.y));

    // Hit object to store information
    HitParams hit;
    const int bounces = 1; // Dont go beyond 20
    float energy = 0.5;
    float decay_multiplier = 0.9;

    // Ray initial cast
    // Creating ray
    Ray r;
    r.origin = cam.position;
    r.direction = normalize(canvas_position - r.origin);
    // Created ray

    hit = trace(r, pointlights, planes, spheres);
    vec3 diff_color = hit.color;
    vec3 diff_light = hit.light;
    vec3 hit_point = hit.position;
    vec3 obj_normal = hit.normal;

    // Reflection bounce
    vec3 mul_color = diff_color;
    vec3 light = diff_light;
    vec3 total_bounce_color = mul_color * energy;
    vec3 prev_hit_point = hit_point;
    vec3 prev_normal = obj_normal;
    vec3 prev_ray_dir = r.direction;
    for(int i=0; i<bounces; i++){
        r.origin = prev_hit_point + prev_normal * 0.00001;
        r.direction = prev_ray_dir - (prev_normal * (dot(prev_ray_dir, prev_normal) * 2.0));
        hit = trace(r, pointlights, planes, spheres);
        energy = energy * decay_multiplier;
        mul_color *= hit.color;
        light += hit.light * energy;
        total_bounce_color += mul_color;
        prev_hit_point = hit.position;
        prev_normal = hit.normal;
        prev_ray_dir = r.direction;
    }
    total_bounce_color *= light;

    vec3 total_color = total_bounce_color;

    // Clipping total color
    if(total_color.x > 1.0){ total_color.x = 1.0; }
    if(total_color.y > 1.0){ total_color.y = 1.0; }
    if(total_color.z > 1.0){ total_color.z = 1.0; }

    gl_FragColor = vec4(total_color, 1);

}