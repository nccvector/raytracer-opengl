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
    vec3 object_normal = EmptyVector;
    float min_dist = MathInf;

    // Check collision against all planes
    for(int i=0; i<num_planes; i++){
        vec3 hit_point = hit(planes[i], r);
        float dist = distance(hit_point, r.origin);

        if(dist < min_dist){
            min_dist = dist;
            closest_hit_point = hit_point;
            color = planes[i].color;
            object_normal = calculate_normal(planes[i], closest_hit_point);
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
            object_normal = calculate_normal(spheres[i], closest_hit_point);
        }
    }

    // Calculating shadow ray
    if(closest_hit_point != EmptyVector){
        vec3 total_lightcolor = vec3(0,0,0);
        for(int l=0; l<num_pointlights; l++){

            bool object_in_way = false;
            float intensity = 1.0;
            vec3 lightcolor = pointlights[l].color * pointlights[l].intensity;

            Ray shadow_ray;
            vec3 shadow_Ray_direction = normalize(pointlights[l].position - closest_hit_point);
            shadow_ray.origin = closest_hit_point + (object_normal * 0.00001);
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
                float diff_angle = dot(shadow_ray.direction, object_normal);
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

        color *= total_lightcolor;
        
    }

    HitParams cc;
    cc.color = color;
    cc.position = closest_hit_point;
    cc.normal = object_normal;
    return cc;

}

void main() {
    vec2 st = gl_FragCoord.xy / u_resolution.xy;
    st.x *= u_resolution.x / u_resolution.y;

    // Creating Point
    PointLight L;
    L.position = vec3(distance_lights * sin(u_time), 
    0.2, distance_lights * cos(u_time));
    L.color = vec3(0.2784, 0.2784, 0.5882);
    L.intensity = 0.25 + ambient_intensity;

    PointLight L2;
    L2.position = vec3(distance_lights * cos(u_time), 
    0.2, distance_lights * sin(u_time));
    L2.color = vec3(0.6275, 0.251, 0.251);
    L2.intensity = 0.8 + ambient_intensity;

    PointLight pointlights[num_pointlights];
    pointlights[0] = L;
    pointlights[1] = L2;

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

    Sphere spheres[num_spheres];
    spheres[0] = S;
    spheres[1] = S2;
    spheres[2] = S3;

    // Creating plane
    Plane p; // Floor
    p.position = vec3(0.0,-0.1,0.0);
    p.normal = vec3(0.0,1.0,0.0);
    p.color = vec3(0.8,0.8,0.8);

    Plane p2; // Left
    p2.position = vec3(0.3,0.0,0.0);
    p2.normal = vec3(-1.0,0.0,0.0);
    p2.color = vec3(0.6275, 0.1333, 0.1333);

    Plane p3; // Right
    p3.position = vec3(-0.3,0.0,0.0);
    p3.normal = vec3(1.0,0.0,0.0);
    p3.color = vec3(0.1647, 0.6392, 0.149);

    Plane p4; // Back
    p4.position = vec3(0.0,0.0,-0.4);
    p4.normal = vec3(0.0,0.0,1.0);
    p4.color = vec3(0.149, 0.149, 0.5922);

    Plane p5; // Ceiling
    p5.position = vec3(0.0,0.3,0.0);
    p5.normal = vec3(0.0,-1.0,0.0);
    p5.color = vec3(0.8,0.8,0.8);

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

    vec3 average_sphere_pos = S.position + S2.position;
    average_sphere_pos = average_sphere_pos * 0.5;
    average_sphere_pos.y = 0.05;

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
    
    // Creating ray
    Ray r;
    r.origin = cam.position;
    r.direction = normalize(canvas_position - r.origin);
    // Created ray

    // Hit object to store information
    HitParams hit;

    // Ray initial cast
    hit = trace(r, pointlights, planes, spheres);

    gl_FragColor = vec4(hit.color,1);

}