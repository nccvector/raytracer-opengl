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

    float canvas_distance;
    vec3 canvas_origin;
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

void main() {
    vec2 st = gl_FragCoord.xy / u_resolution.xy;
    st.x *= u_resolution.x / u_resolution.y;

    // Ambient Light Intensity
    float ambient_intensity = 0.3;

    // Creating Point
    PointLight L;
    L.position = vec3(5.0*sin(u_time),2,3.0*cos(u_time));
    L.color = vec3(1,1,1);
    L.intensity = 1.0;

    // Creating spheres
    Sphere S;
    S.position = vec3(0.15, 0.0, 0.0);
    S.radius = 0.1;
    S.color = vec3(0.0, 1.0, 0.0);

    Sphere S2;
    S2.position = vec3(-0.15, 0.0, 0.0);
    S2.radius = 0.1;
    S2.color = vec3(0.0, 0.0, 1.0);

    Sphere S3;
    S3.position = vec3(0.0, 0.0, -0.2);
    S3.radius = 0.1;
    S3.color = vec3(1.0, 0.0, 0.0);

    const int num_spheres = 3;
    Sphere spheres[num_spheres];
    spheres[0] = S;
    spheres[1] = S2;
    spheres[2] = S3;

    // Creating plane
    Plane p;
    p.position = vec3(0.0,-0.1,0.0);
    p.normal = vec3(0.0,1.0,0.0);
    p.color = vec3(0.5,0.5,0.8);
    // Created objects

    vec3 average_sphere_pos = S.position + S2.position;
    average_sphere_pos = average_sphere_pos * 0.5;

    Camera cam;
    float look_distance = 3.0;
    cam.position = vec3(0, 1, 3);
    cam.forward = normalize(average_sphere_pos - cam.position);
    // cam.forward = vec3(0,0,1);
    cam.right = cross(cam.forward, p.normal);
    cam.down = cross(cam.forward, cam.right);
    cam.canvas_distance = 3.0;
    cam.canvas_origin = cam.position + cam.forward*cam.canvas_distance;

    vec3 canvas_position = cam.canvas_origin + (cam.right * (0.5 - st.x)) + (cam.down * (0.5 - st.y));
    
    // Creating ray
    Ray r;
    r.origin = cam.position;
    r.direction = normalize(canvas_position - r.origin);
    // Created ray

    // Initializing color with background color
    vec3 color = vec3(1);

    // Initializing closest_hit_point and min_dist with plane
    vec3 closest_hit_point = hit(p, r);
    vec3 object_normal = EmptyVector;
    float min_dist = distance(closest_hit_point, r.origin);

    // If plane collision happens then color
    if(closest_hit_point != EmptyVector){
        color = p.color;
        object_normal = calculate_normal(p, closest_hit_point);
    }
    
    // Check collision against all spheres
    for(int i=0; i<num_spheres; i++){
        vec3 hit_point = hit(spheres[i], r);
        float dist = distance(hit_point, r.origin);

        if(dist < min_dist){
            min_dist = dist;
            closest_hit_point = hit_point;
            color = spheres[i].color;
            object_normal = calculate_normal(spheres[i], closest_hit_point);
        }
    }

    // Calculating shadow ray
    bool object_in_way = false;
    if(closest_hit_point != EmptyVector){
        Ray shadow_ray;
        vec3 shadow_Ray_direction = normalize(L.position - closest_hit_point);
        shadow_ray.origin = closest_hit_point + (object_normal * 0.00001);
        shadow_ray.direction = shadow_Ray_direction;

        // Initializing min dist from light distance
        float min_dist = distance(shadow_ray.origin, L.position);

        // Now we will check ray distance against all objects
        // Checking shadow ray against plane
        vec3 hit_point = hit(p, shadow_ray);
        float dist = distance(shadow_ray.origin, hit_point);
        if(dist < min_dist){
            color = color * ambient_intensity;
            object_in_way = true;
        }else{
            // Checking shadow ray against sphere
            for(int i=0; i<num_spheres; i++){
                vec3 hit_point = hit(spheres[i], shadow_ray);
                float dist = distance(shadow_ray.origin, hit_point);

                if(dist < min_dist){
                    color = color * ambient_intensity;
                    object_in_way = true;
                    break;
                }
            }
        }

        if(!object_in_way){
            // Shading
            float diff_angle = dot(shadow_ray.direction, object_normal);
            if(diff_angle < 0.0){
                diff_angle = 0.0;
            }

            float total_intensity = diff_angle + ambient_intensity;
            if(total_intensity > 1.0){
                total_intensity = 1.0;
            }

            color = color * total_intensity;
        }
    }

    gl_FragColor = vec4(color,1);

}